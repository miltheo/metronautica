# Assessment retention, opt-out and signal-state provenance.
library(metronautica)
local({
    count <- 0L
    check <- function(ok) {
        count <<- count + 1L
        if (!isTRUE(ok)) stop("Report attachment check ", count, " failed.")
    }
    fails <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")
    same_samples <- function(a, b) identical(a$time, b$time) &&
        identical(a$ax_g, b$ax_g) && identical(a$ay_g, b$ay_g) && identical(a$az_g, b$az_g)
    records <- function(x, type) accel_meta(x)$processing$reports[[type]]
    fs <- 100
    t0 <- as.POSIXct("2026-01-01", tz = "UTC")
    s <- (0:11999)/fs
    meta <- list(file = list(hash_sha256 = paste(rep("a", 64), collapse = "")),
        acquisition = list(fs_nominal_hz = fs, fs_derived_hz = fs, full_scale_range_g = 16))
    x <- attach_qc(as_accel_tbl(t0 + s, .01 * sin(2*pi*s), .02 * cos(2*pi*s),
        1 + .03 * sin(2*pi*2*s), meta))
    before <- x
    static <- static_metrology_from_tbl(x, start_utc = t0 + 10, duration_h = 60/3600, progress = FALSE)
    off <- static_metrology_from_tbl(x, start_utc = t0 + 10, duration_h = 60/3600,
        progress = FALSE, attach_report = FALSE)
    check(identical(x, before))
    check(same_samples(static$data, x) && nrow(static$clipped_data) == 6000L)
    check(identical(static$summary, off$summary) && identical(static$allan, off$allan))
    check(length(records(static$data, "static")) == 1L && is.null(records(off$data, "static")))
    rec <- records(static$data, "static")[[1L]]
    check(identical(rec, records(static$clipped_data, "static")[[1L]]))
    check(identical(static$meta, accel_meta(static$clipped_data)))
    check(rec$selection$n_samples == 6000L && rec$selection$requested_start_utc == t0 + 10)
    check(identical(rec$results$summary, static$summary) && identical(rec$results$allan, static$allan))
    check(identical(rec$diagnostics, accel_meta(static$clipped_data)$processing$qc))
    check(identical(rec$source$file$hash_sha256, meta$file$hash_sha256))
    check(is.null(rec$source$processing$reports) && is.null(rec$results$clipped_data) &&
        is.null(rec$results$drift_plot))
    noise <- static_noise_summary_from_tbl(static$data, start_utc = t0, duration_h = 60/3600,
        progress = FALSE)
    check(length(records(noise$data, "static")) == 2L)
    check(identical(records(noise$data, "static")[[2]]$function_name, "static_noise_summary_from_tbl"))
    check(identical(noise$meta, accel_meta(noise$clipped_data)))
    noise_off <- static_noise_summary_from_tbl(x, start_utc = t0, duration_h = 60/3600,
        progress = FALSE, attach_report = FALSE)
    check(is.null(records(noise_off$data, "static")))
    # Persist metadata exports from the noise-only path as well as returned data.
    output <- tempfile("metronautica-attachment-")
    dir.create(output)
    saved <- static_noise_summary_from_tbl(x, start_utc = t0, duration_h = 60/3600,
        progress = FALSE, out_dir = output)
    check(identical(readRDS(saved$files$meta_rds), saved$meta))
    archive <- tempfile(fileext = ".rds")
    saveRDS(noise$data, archive)
    check(identical(readRDS(archive), noise$data))
    features <- function(z) compute_accel_summaries(z, measures = c("ENMO", "MAD"), epoch_s = 5, quiet = TRUE)
    check(identical(features(noise$data), features(x)))
    check(identical(formals(static_metrology_from_tbl)$attach_report, TRUE) &&
        identical(formals(static_noise_summary_from_tbl)$attach_report, TRUE) &&
        identical(formals(dynamic_metrology_report)$attach_report, TRUE))
    for (bad in list(NA, 1, "TRUE", c(TRUE, FALSE), NULL)) {
        check(fails(static_metrology_from_tbl(x, start_utc = t0, duration_h = 60/3600, attach_report = bad)))
        check(fails(static_noise_summary_from_tbl(x, start_utc = t0, duration_h = 60/3600, attach_report = bad)))
    }
    filtered <- filter_accel_tbl(noise$data, cutoff = 10)
    check(all(vapply(records(filtered, "static"), function(r) r$status == "historical", logical(1))))
    check(records(noise$data, "static")[[1]]$status == "current")
    clipped <- clip_bundle(noise$data, start_time = t0, duration_s = 10)
    check(all(vapply(records(clipped, "static"), function(r) r$status == "historical", logical(1))))
    calibration <- data.frame(vm_calibration_intercept = 0, vm_calibration_slope = 1.1,
        vm_calibration_quadratic = 0, vm_calibration_direction = "ref_on_test")
    calibrated <- dm_apply_vm_calibration_tbl(noise$data, calibration)
    check(records(calibrated, "static")[[1]]$status == "historical")
    bundle <- function(z) clip_dynamic_stages(z, t0, n_stages = 2, stage_min = 1,
        buffer_min = 0, rpm_start = 50, rpm_step = 50, trim_start_min = 0, trim_end_min = 0)
    test <- bundle(noise$data)
    ref <- bundle(x)
    test_before <- test
    run <- function(a = test, ...) dynamic_metrology_report(a, ref, compute_entropy = FALSE,
        add_plot = FALSE, inspect_alignment = FALSE, progress = FALSE, ...)
    dyn <- run()
    dyn_off <- run(attach_report = FALSE)
    check(identical(test, test_before) && identical(x, before))
    check(identical(dyn$stages, dyn_off$stages) && identical(dyn$overall, dyn_off$overall))
    check(same_samples(dyn$data, test$full))
    check(length(records(dyn$data, "dynamic")) == 1L && is.null(records(dyn_off$data, "dynamic")))
    check(identical(dyn$test_clips$meta, accel_meta(dyn$test_clips$full)))
    record <- records(dyn$data, "dynamic")[[1]]
    check(identical(record, records(dyn$test_clips$full, "dynamic")[[1]]))
    check(all(vapply(dyn$test_clips$stages, function(z) identical(record, records(z, "dynamic")[[1]]), logical(1))))
    check(identical(record$results$stages, dyn$stages) && identical(record$results$overall, dyn$overall))
    check(identical(record$reference$source$file$hash_sha256, meta$file$hash_sha256))
    check(record$diagnostics$test$rpm_50$n_samples == 6000L &&
        record$selection$stages$rpm_100$n_samples == 6000L)
    check(is.null(record$results$plots) && is.null(record$reference$source$processing$reports))
    again <- run(dyn$test_clips)
    check(length(records(again$data, "dynamic")) == 2L)
    stages_only <- test
    stages_only$full <- NULL
    from_stages <- run(stages_only)
    check(nrow(from_stages$data) == 12000L && length(records(from_stages$data, "dynamic")) == 1L)
    check(identical(from_stages$test_clips$meta, accel_meta(from_stages$data)))
    bare <- test
    attr(bare$full, "meta") <- NULL
    bare$stages <- lapply(bare$stages, function(z) {attr(z, "meta") <- NULL; z})
    from_bundle <- run(bare)
    check(identical(accel_meta(from_bundle$data)$acquisition, test$meta$acquisition))
    for (bad in list(NA, 1, "TRUE", c(TRUE, FALSE), NULL)) check(fails(run(attach_report = bad)))
    parser_bundle <- list(data = x, meta = accel_meta(x))
    from_parser <- static_noise_summary_from_tbl(parser_bundle, start_utc = t0,
        duration_h = 60/3600, progress = FALSE)
    check(same_samples(from_parser$data, x) && length(records(from_parser$data, "static")) == 1L)
    saveRDS(dyn$test_clips, archive)
    check(identical(readRDS(archive), dyn$test_clips))
    cat(count, "assessment attachment, persistence, opt-out and provenance checks passed.\n")
})
