# Public function integration checks.
library(metronautica)
e <- asNamespace("metronautica")
identity_meta <- get("meta_min_template", e)("synthetic.csv", "ax3_csv", hash_sha256 = "synthetic-test-digest")
stopifnot(identical(identity_meta$file$auto_parser, "m_parsers"))
fs <- 100
t <- as.POSIXct("2026-01-01", tz = "UTC") + (0:11999)/fs
s <- (0:11999)/fs
x <- as_accel_tbl(t, 0.1 * sin(2 * pi * 2 * s), 0.2 * cos(2 * pi * 2 * s), 1 + 0.15 * sin(2 * pi * 3 *
    s), list(acquisition = list(fs_derived_hz = fs, fs_nominal_hz = fs, full_scale_range_g = 16)))
b <- list(data = x, meta = accel_meta(x))
for (input in list(x, b, tibble::as_tibble(x))) {
    stopifnot(identical(qc_accel_tbl(input), qc_accel_tbl(x)))
    stopifnot(identical(accel_metric_enmo(input, 5), accel_metric_enmo(x, 5)))
    stopifnot(identical(static_allan(input), static_allan(x)))
}
stopifnot(qc_accel_tbl(b)$ruleset == "primary-five")
if (requireNamespace("plotly", quietly = TRUE)) {
    raw_plot <- plotly::plotly_build(plot_accel_clip(b, include_vm = TRUE))
    summaries <- compute_accel_summaries(b, measures = "ENMO", epoch_s = 5)
    processed_plot <- plotly::plotly_build(plot_processed_metric(summaries, "ENMO"))
    stopifnot(inherits(raw_plot, "plotly"), inherits(processed_plot, "plotly"), length(raw_plot$x$data) ==
        4L, length(processed_plot$x$data) == 1L)
}
stopifnot(identical(accel_meta(attach_qc(b))$processing$qc, qc_accel_tbl(x)))
stopifnot(is.null(accel_meta(invalidate_qc(attach_qc(b)))$processing$qc))
ref <- 1 + 0.25 * sin(2 * pi * 2 * s)
test <- 0.02 + 1.1 * ref + 0.001 * cos(2 * pi * 7 * s)
direct <- m_dynamic_response(test, ref, 16)
fit <- stats::lm(test ~ ref)
residual <- max(abs(test - stats::predict(fit)))
stopifnot(abs(direct$response_slope - unname(coef(fit)[2])) < 1e-12, abs(direct$linearity_error_vs_reference -
    100 * residual/(sqrt(3) * 16)) < 1e-12, abs(direct$composite_error - 100 * residual/(sqrt(3) * 16/2)) <
    1e-12)
# Test retrieval using offline fixtures.
local({
    folder <- tempfile("metronautica-loader-")
    dir.create(folder)
    on.exit(unlink(folder, recursive = TRUE), add = TRUE)
    storage <- file.path(folder, "storage")
    dir.create(storage)
    catalogue <- file.path(folder, "catalogue")
    dir.create(catalogue)
    dest <- file.path(folder, "restored")
    rows <- lapply(c("LEAP", "REFERENCE"), function(device) {
        input <- system.file("extdata", if (device == "LEAP")
            "leap_reference.agsd" else "example_motion.csv", package = "metronautica", mustWork = TRUE)
        name <- if (device == "LEAP")
            "dynamic_leap.agsd" else "dynamic_reference_primary.csv"
        bytes <- readBin(input, "raw", n = file.info(input)$size)
        gzip <- file.path(storage, paste0(name, ".gz"))
        con <- gzfile(gzip, "wb")
        writeBin(bytes, con)
        close(con)
        data.frame(device = device, type = "dynamic", file_name = name, storage_file = basename(gzip),
            native_sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE), storage_sha256 = digest::digest(file = gzip,
                algo = "sha256"), time_shift_s = if (device == "REFERENCE")
                3600 else 0)
    })
    index <- do.call(rbind, rows)
    write.csv(index, file.path(storage, "sample_index.csv"), row.names = FALSE)
    write.csv(index, file.path(catalogue, "sample_index.csv"), row.names = FALSE)
    path <- m_load_sample_data("LEAP", "dynamic", dest_dir = dest, sample_dir = storage)
    stopifnot(file.exists(path), file.exists(attr(path, "reference_file")), attr(path, "reference_info")$time_shift_s ==
        3600, file.exists(paste0(path, ".json")))
    again <- m_load_sample_data("LEAP", "dynamic", dest_dir = dest, sample_dir = catalogue)
    stopifnot(identical(path, again))  # Reuse verified files without sources.
    one <- m_load_sample_data("LEAP", "dynamic", dest_dir = dest, sample_dir = storage, include_reference = FALSE)
    stopifnot(is.null(attr(one, "reference_file")))
    old <- options(metronautica.sample_dir = storage)
    stopifnot(identical(as.character(path), as.character(m_load_sample_data("leap", "DYNAMIC", dest_dir = dest))))
    options(old)
    # Exercise file:/// transport offline.
    url <- paste0("file:///", utils::URLencode(normalizePath(storage, winslash = "/"), reserved = FALSE))
    remote <- m_load_sample_data("LEAP", "dynamic", dest_dir = file.path(folder, "download"), sample_dir = catalogue,
        base_url = url)
    stopifnot(identical(readBin(path, "raw", n = file.info(path)$size), readBin(remote, "raw", n = file.info(remote)$size)))
    protected <- file.path(folder, "protected")
    dir.create(protected)
    target <- file.path(protected, "dynamic_leap.agsd")
    writeBin(charToRaw("existing project file"), target)
    stopifnot(inherits(try(m_load_sample_data("LEAP", "dynamic", dest_dir = protected, sample_dir = storage),
        silent = TRUE), "try-error"))
    corrupt <- file.path(folder, "corrupt")
    dir.create(corrupt)
    write.csv(index, file.path(corrupt, "sample_index.csv"), row.names = FALSE)
    writeBin(charToRaw("bad compressed data"), file.path(corrupt, index$storage_file[1]))
    stopifnot(inherits(try(m_load_sample_data("LEAP", "dynamic", dest_dir = protected, sample_dir = corrupt,
        overwrite = TRUE), silent = TRUE), "try-error"), identical(readBin(target, "raw", n = 100), charToRaw("existing project file")))
    # Reject incorrect restored checksums.
    damaged <- index
    damaged$native_sha256[1] <- paste(rep("0", 64), collapse = "")
    write.csv(damaged, file.path(catalogue, "sample_index.csv"), row.names = FALSE)
    stopifnot(inherits(try(m_load_sample_data("LEAP", "dynamic", dest_dir = protected, sample_dir = catalogue,
        base_url = url, overwrite = TRUE), silent = TRUE), "try-error"), identical(readBin(target, "raw",
        n = 100), charToRaw("existing project file")))
    write.csv(index, file.path(catalogue, "sample_index.csv"), row.names = FALSE)
    stopifnot(inherits(try(m_load_sample_data("LEAP", "dynamic", dest_dir = file.path(folder, "missing"),
        sample_dir = catalogue), silent = TRUE), "try-error"), inherits(try(m_load_sample_data("LEAP",
        "dynamic", sample_dir = catalogue, base_url = paste0(url, "/missing"), dest_dir = file.path(folder,
            "unavailable")), silent = TRUE), "try-error"))
})

# Opt into full-recording validation.
# Keep routine checks offline.
if (nzchar(Sys.getenv("METRONAUTICA_SAMPLE_DIR"))) local({
    data_dir <- Sys.getenv("METRONAUTICA_SAMPLE_DIR")
    old_options <- options(metronautica.sample_dir = data_dir)
    on.exit(options(old_options), add = TRUE)
    index <- utils::read.csv(file.path(data_dir, "sample_index.csv"))
    stopifnot(nrow(index) == 9L, setequal(index$device, c("LEAP", "AX3", "SENS", "GENEACTIV", "REFERENCE")))
    folder <- tempfile("metronautica-example-")
    path <- m_load_sample_data("LEAP", "dynamic", dest_dir = folder)
    stopifnot(file.exists(path), file.exists(paste0(path, ".json")))
    stopifnot(identical(as.character(path), as.character(m_load_sample_data("leap", "DYNAMIC", dest_dir = folder))))
    info <- attr(path, "sample_info")
    ref_path <- attr(path, "reference_file")
    ref_info <- attr(path, "reference_info")
    stopifnot(file.exists(ref_path), ref_info$device == "REFERENCE", ref_info$time_shift_s == 3600, digest::digest(file = ref_path,
        algo = "sha256") == ref_info$native_sha256)
    parsed <- parse_raw_auto(path, return = "bundle", full_scale_range_g = info$full_scale_range_g)
    stopifnot(parsed$meta$processing$qc$ruleset == "primary-five", identical(parsed$meta, accel_meta(parsed$data)))
    stages <- clip_dynamic_stages(parsed, start_utc = info$trial_start_utc, n_stages = 10L, stage_min = 6,
        buffer_min = 2, rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
    stopifnot(length(stages$stages) == 10L, all(lengths(lapply(stages$stages, function(z) z$time)) >
        0))
    reference <- parse_raw_auto(ref_path, return = "bundle", time_shift_s = ref_info$time_shift_s, full_scale_range_g = ref_info$full_scale_range_g)
    ref_stages <- clip_dynamic_stages(reference, start_utc = ref_info$trial_start_utc, n_stages = 10L,
        stage_min = 6, buffer_min = 2, rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
    paired <- dynamic_metrology_report(stages, ref_stages, test_axis_fsr_g = info$full_scale_range_g,
        ref_axis_fsr_g = ref_info$full_scale_range_g, compute_entropy = FALSE, inspect_alignment = FALSE,
        add_plot = FALSE, progress = FALSE)
    stopifnot(nrow(paired$stages) == 10L, all(is.finite(paired$stages$response_slope)))
    without_ref <- m_load_sample_data("LEAP", "dynamic", dest_dir = folder, include_reference = FALSE)
    stopifnot(is.null(attr(without_ref, "reference_file")))
    # Retain complete native trial samples.
    stopifnot(min(parsed$data$time) <= as.POSIXct(info$analysis_start_utc, tz = "UTC"), max(parsed$data$time) >=
        as.POSIXct(info$analysis_end_utc, tz = "UTC") - 1)
    bad <- file.path(folder, "dynamic_ax3.cwa")
    writeBin(charToRaw("existing project file"), bad)
    stopifnot(inherits(try(m_load_sample_data("AX3", "dynamic", dest_dir = folder), silent = TRUE), "try-error"),
        identical(readBin(bad, "raw", n = 100), charToRaw("existing project file")))
    unlink(folder, recursive = TRUE)
})
stopifnot(!exists(".metronautica_call", envir = e, inherits = FALSE), !exists("metronautica_metrology",
    envir = e, inherits = FALSE))
cat("Direct API, offline sample loader, default QC and dynamic primitive checks passed\n")
