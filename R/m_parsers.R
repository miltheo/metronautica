# Native triaxial recording parsers.
# Input: supported recording file.
# Output: acceleration table and metadata.

AUTO_PARSER_NAME <- "m_parsers"
AUTO_PARSER_VERSION <- "1.0.0"
MJT_DEVICE_PARSER_VERSION <- "1.0.0"
MJT_AX3_CWA_PARSER_NAME <- "mjt_ax3_cwa_parser"
MJT_AX3_CSV_PARSER_NAME <- "mjt_ax3_csv_parser"
MJT_SENS_PARSER_NAME <- "mjt_sens_parser"
MJT_LEAP_CSV_PARSER_NAME <- "mjt_leap_csv_parser"
MJT_LEAP_AGSD_PARSER_NAME <- "mjt_leap_agsd_parser"

# Dependencies ----
required_pkgs <- c("tibble", "digest", "jsonlite")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs)) stop("Missing packages: ", paste(missing_pkgs, collapse = ", "))

# Utilities ----
`%m_parser_or%` <- function(a, b) if (is.null(a)) b else a

# Common acceleration data format ----
as_accel_tbl <- function(time, ax_g, ay_g, az_g, meta = list()) {
    axes <- list(ax_g, ay_g, az_g)
    if (!inherits(time, "POSIXct") || !is.list(meta) || !all(vapply(axes, is.numeric, logical(1))) ||
        any(lengths(axes) != length(time)))
        stop("time must be POSIXct; axes must be numeric vectors of the same length; meta must be a list",
            call. = FALSE)
    x <- tibble::tibble(time = time, ax_g = ax_g, ay_g = ay_g, az_g = az_g)
    attr(x, "meta") <- meta
    class(x) <- c("accel_tbl", class(x))
    x
}

# Unwrap tables without modifying samples.
# Prefer table metadata.
accel_meta <- function(x) {
    if (is.data.frame(x))
        return(attr(x, "meta"))
    if (is.list(x)) {
        for (field in c("full", "data")) {
            if (is.data.frame(x[[field]])) {
                meta <- attr(x[[field]], "meta")
                return(if (is.null(meta)) x$meta else meta)
            }
        }
    }
    attr(x, "meta")
}

pick_col <- function(d, candidates) {
    hit <- intersect(candidates, names(d))
    if (!length(hit))
        stop("Missing required column: ", paste(candidates, collapse = " or "))
    d[[hit[1]]]
}

derive_fs <- function(time_posix) {
    dt <- diff(as.numeric(time_posix))
    dt <- dt[is.finite(dt) & dt > 0]
    if (!length(dt))
        return(NA_real_)
    1/stats::median(dt, na.rm = TRUE)
}

mk_pb <- function(enabled = FALSE, steps = 4L) {
    if (!isTRUE(enabled))
        return(NULL)
    utils::txtProgressBar(min = 0, max = steps, style = 3)
}

pb_step <- function(pb, i) {
    if (is.null(pb))
        return(invisible(NULL))
    utils::setTxtProgressBar(pb, i)
    invisible(NULL)
}

pb_close <- function(pb) {
    if (is.null(pb))
        return(invisible(NULL))
    close(pb)
    invisible(NULL)
}

pm_to_fullscale <- function(x) {
    if (is.na(x) || !is.finite(x))
        return(NA_real_)
    2 * as.numeric(x)  # +/- -> full scale
}

# Metadata ----

# Acquisition and processing metadata ----
meta_min_template <- function(path, format, auto_parser = AUTO_PARSER_NAME, auto_parser_version = AUTO_PARSER_VERSION,
    parser = NA_character_, parser_version = NA_character_, hash_sha256 = NULL) {
    file_hash <- hash_sha256 %m_parser_or% digest::digest(file = path, algo = "sha256")
    list(file = list(source_path = path, source_name = basename(path), format = format, bytes = as.numeric(file.info(path)$size),
        hash_sha256 = file_hash, auto_parser = auto_parser, auto_parser_version = auto_parser_version,
        parser = parser, parser_version = parser_version, parsed_utc = format(Sys.time(), tz = "UTC",
            usetz = TRUE), warnings = character(0)), acquisition = list(start_utc = as.POSIXct(NA, tz = "UTC"),
        end_utc = as.POSIXct(NA, tz = "UTC"), fs_nominal_hz = NA_real_, fs_derived_hz = NA_real_, full_scale_range_g = NA_real_,
        units = "g", device_vendor = NA_character_, device_model = NA_character_, device_id = NA_character_,
        sensor_vendor = NA_character_, sensor_model = NA_character_, time_tz_declared = NA_character_,
        time_tz_parsed = NA_character_, time_tz_source = "unknown", time_shift_s = 0), processing = list(parser_library = list(name = auto_parser,
        version = auto_parser_version), calibration = list(status = "not_recorded", scale_applied = NA,
        calibration_applied = NA, scale_source = NA_character_, calibration_source = NA_character_, applied_by = NA_character_,
        details = list(), notes = "", caveats = character(0)), decode_notes = ""))
}

named_numeric_list <- function(x, names = NULL) {
    x <- as.numeric(x)
    if (!is.null(names))
        names(x) <- names
    as.list(x)
}

matrix_row_lists <- function(x, names = NULL) {
    lapply(seq_len(nrow(x)), function(i) named_numeric_list(x[i, ], names = names))
}

# Record decoding coefficient provenance ----
set_calibration_provenance <- function(meta, status, scale_applied, calibration_applied, scale_source,
    calibration_source = NA_character_, applied_by = NA_character_, details = list(), notes = "", caveats = character(0)) {
    meta$processing$calibration <- list(status = status, scale_applied = isTRUE(scale_applied), calibration_applied = isTRUE(calibration_applied),
        scale_source = scale_source, calibration_source = calibration_source, applied_by = applied_by,
        details = details, notes = notes, caveats = caveats)
    meta
}

apply_time_policy <- function(time, meta, tz_declared = NA_character_, tz_parsed = "UTC", tz_source = "unknown",
    time_shift_s = 0) {
    stopifnot(inherits(time, "POSIXct"))
    meta$acquisition$time_tz_declared <- tz_declared
    meta$acquisition$time_tz_parsed <- tz_parsed
    meta$acquisition$time_tz_source <- tz_source
    meta$acquisition$time_shift_s <- as.numeric(time_shift_s)
    time <- time + as.numeric(time_shift_s)
    attr(time, "tzone") <- "UTC"
    list(time = time, meta = meta)
}

# GENEActiv header helpers ----
header_kv_from_genearead <- function(h) {
    if (is.null(h) || !nrow(h))
        return(list())
    out <- as.list(as.character(h$Value))
    names(out) <- rownames(h)
    out
}

kv_get <- function(kv, key) {
    if (!length(kv) || is.null(kv[[key]]) || kv[[key]] == "")
        return(NA_character_)
    kv[[key]]
}

# Axivity helper ----

# Axivity binary decoding ----
cwa_last_block <- function(path) {
    stopifnot(file.exists(path))
    file_size <- as.numeric(file.info(path)$size)  # bytes
    stopifnot(is.finite(file_size) && file_size > 0)
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    hdr <- readBin(con, what = "raw", n = min(1024, file_size))
    if (length(hdr) < 4)
        stop("CWA header too small to parse.")
    if (!(hdr[1] == charToRaw("M") && hdr[2] == charToRaw("D")))
        stop("CWA header does not start with 'MD'.")
    packet_len <- readBin(hdr[3:4], what = "integer", size = 2, signed = FALSE, endian = "little", n = 1)
    header_size <- as.numeric(packet_len) + 4  # header bytes
    if (!is.finite(header_size) || header_size <= 0)
        stop("Bad CWA header size.")
    if (file_size <= header_size)
        return(-1L)
    n_blocks <- floor((file_size - header_size)/512)
    if (!is.finite(n_blocks) || n_blocks <= 0)
        return(-1L)
    as.integer(n_blocks - 1L)
}

cwa_decode_timestamp <- function(coded, fraction, shift, tz = "UTC") {
    year <- floor(coded/2^26)%%64 + 2000
    month <- floor(coded/2^22)%%16
    day <- floor(coded/2^17)%%32
    hour <- floor(coded/2^12)%%32
    minute <- floor(coded/2^6)%%64
    second <- coded%%64
    as.numeric(ISOdatetime(year, month, day, hour, minute, second, tz = tz)) + fraction/65536 - shift
}

cwa_block_metadata_fast <- function(path, chunk_blocks = 50000L, tz = "UTC") {
    file_size <- as.numeric(file.info(path)$size)  # bytes
    n_blocks <- as.integer(round(file_size/512) - 2L)
    if (!is.finite(n_blocks) || n_blocks <= 0)
        stop("No CWA data blocks detected after header.")
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    seek(con, 1024, origin = "start")
    start <- numeric(n_blocks)
    len <- integer(n_blocks)
    freq <- numeric(n_blocks)
    scale_code <- integer(n_blocks)  # accel scale code
    axes <- integer(n_blocks)
    packed <- logical(n_blocks)
    ok <- logical(n_blocks)
    offset <- 0L  # block offset
    while (offset < n_blocks) {
        n_read <- min(as.integer(chunk_blocks), n_blocks - offset)
        raw <- readBin(con, what = "raw", n = 512L * n_read)
        if (length(raw) != 512L * n_read)
            stop("Unexpected end of CWA data blocks.")
        m <- matrix(raw, ncol = 512L, byrow = TRUE)
        idx <- seq.int(offset + 1L, offset + n_read)
        u16 <- function(i) as.integer(m[, i]) + as.integer(m[, i + 1L]) * 256L
        i16 <- function(i) {
            value <- u16(i)
            value[value >= 32768L] <- value[value >= 32768L] - 65536L
            value
        }
        u32 <- function(i) as.numeric(m[, i]) + as.numeric(m[, i + 1L]) * 256 + as.numeric(m[, i + 2L]) *
            65536 + as.numeric(m[, i + 3L]) * 16777216
        ts_offset <- u16(5L)  # timestamp fraction/format
        time_stamp <- u32(15L)  # packed timestamp
        offset18 <- u16(19L)  # light + accel scale
        samplerate_dynrange <- as.integer(m[, 25L])
        offset25 <- as.integer(m[, 26L])
        offset26 <- i16(27L)  # timestamp sample offset
        len[idx] <- u16(29L)
        freq[idx] <- round(3200/2^(15 - (samplerate_dynrange%%16)))
        format <- ifelse(floor(ts_offset/32768L) != 0, 1L, 2L)  # CWA timestamp format
        fraction <- ifelse(format == 1L, (ts_offset%%32768L) * 2L, 0L)  # fractional timestamp
        shift_samples <- offset26 + ifelse(format == 1L, floor((fraction * freq[idx])/65536), 0)
        start[idx] <- cwa_decode_timestamp(time_stamp, fraction, shift_samples/freq[idx], tz)
        scale_code[idx] <- floor(offset18/8192L)  # accel scale code
        axes[idx] <- floor(offset25/16L)
        packed[idx] <- (offset25%%16L) == 0L
        ok[idx] <- m[, 1L] == charToRaw("A") & m[, 2L] == charToRaw("X") & u16(3L) == 508L
        offset <- offset + n_read
    }
    list(start = start, len = len, freq = freq, scale_code = scale_code, axes = axes, packed = packed,
        ok = ok)
}

cwa_sign10 <- function(value) {
    value <- as.integer(value)
    value[value >= 512L] <- value[value >= 512L] - 1024L
    value
}

cwa_decode_packed_words <- function(packed_words) {
    packed_words <- as.numeric(packed_words)
    exponent <- floor(packed_words/2^30)
    x <- cwa_sign10(packed_words%%1024) * 2^exponent
    y <- cwa_sign10(floor(packed_words/2^10)%%1024) * 2^exponent
    z <- cwa_sign10(floor(packed_words/2^20)%%1024) * 2^exponent
    list(x = x, y = y, z = z)
}

# Packed AX3 CWA parser ----
parse_axivity_cwa_mjt <- function(path, desiredtz = "UTC", sensor_vendor = NA_character_, sensor_model = NA_character_,
    full_scale_range_g = NA_real_, time_shift_s = 0, return = c("data", "bundle"), hash_sha256 = NULL,
    chunk_blocks = 100000L) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    meta <- meta_min_template(path, "axivity_cwa", parser = MJT_AX3_CWA_PARSER_NAME, parser_version = MJT_DEVICE_PARSER_VERSION,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "Axivity"
    meta$acquisition$device_model <- "AX3"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    header_con <- file(path, "rb")
    on.exit(close(header_con), add = TRUE)
    header <- readBin(header_con, what = "raw", n = 1024L)
    if (length(header) < 1024L || !(header[1L] == charToRaw("M") && header[2L] == charToRaw("D"))) {
        stop("CWA header does not start with 'MD'.")
    }
    h_u16 <- function(i) as.integer(header[i]) + as.integer(header[i + 1L]) * 256L
    h_u32 <- function(i) as.numeric(header[i]) + as.numeric(header[i + 1L]) * 256 + as.numeric(header[i +
        2L]) * 65536 + as.numeric(header[i + 3L]) * 16777216
    lower_device_id <- h_u16(6L)
    upper_device_id <- h_u16(12L)
    if (upper_device_id == 65535L)
        upper_device_id <- 0L
    device_id <- upper_device_id * 65536 + lower_device_id
    samplerate_dynrange <- as.integer(header[37L])
    header_frequency <- round(3200/2^(15 - (samplerate_dynrange%%16)))
    accrange <- bitwShiftR(16L, bitwShiftR(samplerate_dynrange, 6L))
    meta$acquisition$device_id <- as.character(device_id)
    meta$acquisition$fs_nominal_hz <- header_frequency
    if (!is.finite(meta$acquisition$full_scale_range_g))
        meta$acquisition$full_scale_range_g <- pm_to_fullscale(accrange)
    block_meta <- cwa_block_metadata_fast(path, chunk_blocks = max(1000L, as.integer(chunk_blocks)),
        tz = desiredtz)
    supported <- all(block_meta$ok) && all(block_meta$packed) && all(block_meta$axes == 3L) && length(unique(block_meta$len)) ==
        1L && length(unique(block_meta$freq)) == 1L
    if (!supported)
        stop(MJT_AX3_CWA_PARSER_NAME, " supports regular packed 3-axis AX3 CWA files only.")
    block_len <- as.integer(block_meta$len[1L])
    n_blocks <- length(block_meta$start)
    total_samples <- as.double(n_blocks) * as.double(block_len)
    if (total_samples > .Machine$integer.max)
        stop("CWA file is too large for current in-memory R parser.")
    total_samples <- as.integer(total_samples)
    next_start <- c(block_meta$start[-1L], block_meta$start[n_blocks] + stats::median(diff(block_meta$start),
        na.rm = TRUE))
    time_num <- numeric(total_samples)
    ax <- numeric(total_samples)
    ay <- numeric(total_samples)
    az <- numeric(total_samples)
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    seek(con, 1024, origin = "start")
    write_pos <- 1L
    block_offset <- 0L  # block offset
    sample_offsets <- seq.int(0L, block_len - 1L)  # within-block sample offsets
    while (block_offset < n_blocks) {
        n_read <- min(as.integer(chunk_blocks), n_blocks - block_offset)
        raw <- readBin(con, what = "raw", n = 512L * n_read)
        if (length(raw) != 512L * n_read)
            stop("Unexpected end of CWA data blocks during decode.")
        m <- matrix(raw, ncol = 512L, byrow = TRUE)
        idx <- seq.int(block_offset + 1L, block_offset + n_read)
        payload <- as.integer(t(m[, 31L:510L, drop = FALSE]))
        words <- matrix(payload, ncol = 4L, byrow = TRUE)  # bytes per packed sample
        packed_words <- as.numeric(words[, 1L]) + as.numeric(words[, 2L]) * 256 + as.numeric(words[,
            3L]) * 65536 + as.numeric(words[, 4L]) * 16777216
        decoded <- cwa_decode_packed_words(packed_words)
        scale <- rep(1/(2^(8 + block_meta$scale_code[idx])), each = block_len)  # per-block scale
        out_idx <- seq.int(write_pos, write_pos + n_read * block_len - 1L)
        block_step <- (next_start[idx] - block_meta$start[idx])/block_len
        time_num[out_idx] <- rep(block_meta$start[idx], each = block_len) + rep(sample_offsets, times = n_read) *
            rep(block_step, each = block_len)
        ax[out_idx] <- decoded$x * scale
        ay[out_idx] <- decoded$y * scale
        az[out_idx] <- decoded$z * scale
        write_pos <- write_pos + n_read * block_len
        block_offset <- block_offset + n_read
    }
    target_step <- 1/block_meta$freq[1L]
    time_res_num <- seq(block_meta$start[1L], block_meta$start[n_blocks] - target_step, by = target_step)
    ax_res <- stats::approx(time_num, ax, xout = time_res_num, rule = 2)[["y"]]
    rm(ax)
    gc(FALSE)
    ay_res <- stats::approx(time_num, ay, xout = time_res_num, rule = 2)[["y"]]
    rm(ay)
    gc(FALSE)
    az_res <- stats::approx(time_num, az, xout = time_res_num, rule = 2)[["y"]]
    rm(az, time_num)
    gc(FALSE)
    time <- as.POSIXct(time_res_num, origin = "1970-01-01", tz = "UTC")  # POSIXct UTC
    res <- apply_time_policy(time, meta, tz_declared = NA_character_, tz_parsed = desiredtz, tz_source = "user",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    cwa_scale_codes <- sort(unique(as.integer(block_meta$scale_code)))  # scale provenance
    meta <- set_calibration_provenance(meta, status = "scale_applied_no_calibration", scale_applied = TRUE,
        calibration_applied = FALSE, scale_source = "CWA per-block accelScaleCode", calibration_source = NA_character_,
        applied_by = MJT_AX3_CWA_PARSER_NAME, details = list(accel_scale_formula = "g_per_lsb = 1 / 2^(8 + accelScaleCode)",
            scale_code_values = named_numeric_list(cwa_scale_codes), scale_factor_values_g_per_lsb = named_numeric_list(1/(2^(8 +
                cwa_scale_codes))), resampling = "linear interpolation onto the nominal CWA sample grid"),
        notes = "The fast AX3 path applies the CWA block scale code. It does not apply additional offset, sensitivity, temperature, or autocalibration correction.",
        caveats = c("Use GGIRread or a validated calibration workflow if offset/sensitivity/autocalibration correction is required."))
    meta$processing$decode_notes <- paste0(MJT_AX3_CWA_PARSER_NAME, " direct packed AX3 decode with 100 Hz linear resampling; no GGIRread QC imputation in fast path.")
    meta$processing$ax3_parser <- list(name = MJT_AX3_CWA_PARSER_NAME, version = MJT_DEVICE_PARSER_VERSION,
        upstream_reference = "GGIRread::readAxivity / OpenMovement CWA AX3 technical format", upstream_reference_version = "GGIRread 1.0.8 parser logic inspected locally",
        implementation_change = "Direct chunked decode of regular packed 3-axis AX3 CWA blocks with vectorised 10-bit mantissa plus exponent unpacking and linear resampling onto the nominal frequency grid.",
        fallback = "Unsupported CWA layouts should use the GGIRread fallback path.")
    x <- as_accel_tbl(time, ax_res, ay_res, az_res, meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# Parsers
calibrate_genea <- TRUE

# GENEActiv BIN parser ----
parse_genea_bin <- function(path, calibrate = calibrate_genea, mmap_load = (.Machine$sizeof.pointer >=
    8), verbose = FALSE, sensor_vendor = NA_character_, sensor_model = NA_character_, full_scale_range_g = NA_real_,
    time_shift_s = 0, return = c("data", "bundle"), hash_sha256 = NULL) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    genea_version <- as.character(utils::packageVersion("GENEAread"))
    meta <- meta_min_template(path, "geneactiv_bin", parser = "GENEAread", parser_version = genea_version,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "ActivInsights"
    meta$acquisition$device_model <- "GENEActiv"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    h <- tryCatch(GENEAread::header.info(binfile = path, more = TRUE), error = function(e) NULL)
    kv <- header_kv_from_genearead(h)
    if (length(kv))
        meta$acquisition$device_id <- kv_get(kv, "Device_Unique_Serial_Code")
    if (length(kv))
        meta$acquisition$fs_nominal_hz <- suppressWarnings(as.numeric(kv_get(kv, "Measurement_Frequency")))
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    if (!is.finite(meta$acquisition$full_scale_range_g) && length(kv)) {
        rng_pm <- suppressWarnings(as.numeric(kv_get(kv, "Measurement_Range")))
        if (!is.na(rng_pm))
            meta$acquisition$full_scale_range_g <- pm_to_fullscale(rng_pm)  # full scale
    }
    acc <- GENEAread::read.bin(binfile = path, calibrate = calibrate, do.temp = FALSE, do.volt = FALSE,
        mmap.load = mmap_load, verbose = verbose)
    d <- as.data.frame(acc$data.out)
    time <- pick_col(d, c("time", "timestamp", "datetime"))
    ax <- pick_col(d, c("x", "X", "ax", "Ax", "accx"))
    ay <- pick_col(d, c("y", "Y", "ay", "Ay", "accy"))
    az <- pick_col(d, c("z", "Z", "az", "Az", "accz"))
    if (!inherits(time, "POSIXct"))
        time <- as.POSIXct(time, tz = "UTC")
    res <- apply_time_policy(time, meta, tz_declared = "UTC", tz_parsed = "UTC", tz_source = "declared",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$processing$geneactiv_parser <- list(name = "GENEAread", version = genea_version, wrapper = "Metronautica parse_genea_bin",
        implementation_change = "GENEAread is retained; mmap.load is enabled by default on 64-bit R and the backend-computed SHA-256 is reused when available.",
        mmap_load = isTRUE(mmap_load))
    meta <- set_calibration_provenance(meta, status = if (isTRUE(calibrate))
        "calibrated_by_upstream"
    else "upstream_scale_without_calibration", scale_applied = TRUE, calibration_applied = isTRUE(calibrate),
        scale_source = "GENEAread GENEActiv .bin decoder and header metadata", calibration_source = if (isTRUE(calibrate))
            "GENEAread calibration values from the GENEActiv .bin header"
        else NA_character_, applied_by = "GENEAread::read.bin", details = list(calibrate_argument = isTRUE(calibrate),
            mmap_load = isTRUE(mmap_load), measurement_frequency_hz = suppressWarnings(as.numeric(kv_get(kv,
                "Measurement_Frequency"))), measurement_range_plus_minus_g = suppressWarnings(as.numeric(kv_get(kv,
                "Measurement_Range")))), notes = "Metronautica keeps GENEAread as the scientific decode path and records whether GENEAread calibration was requested.",
        caveats = if (isTRUE(calibrate))
            character(0)
        else c("GENEAread calibration was disabled for this parse."))
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# SENS BIN parser ----
parse_sens_bin <- function(path, scale_g_per_lsb = 0.0078125, sensor_vendor = NA_character_, sensor_model = NA_character_,
    full_scale_range_g = NA_real_, spec_accessed = "2026-02-25", time_shift_s = 0, return = c("data",
        "bundle"), hash_sha256 = NULL) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    TIMESTAMP_BYTES <- 6L  # bytes
    AXIS_BYTES <- 2L  # bytes
    RECORD_SIZE <- TIMESTAMP_BYTES + 3L * AXIS_BYTES
    upstream_spec_accessed <- spec_accessed %m_parser_or% format(Sys.Date(), "%Y-%m-%d")
    meta <- meta_min_template(path, "sens_bin", parser = MJT_SENS_PARSER_NAME, parser_version = MJT_DEVICE_PARSER_VERSION,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "SENs"
    meta$acquisition$device_model <- "SENs motion"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    meta$processing$decode_notes <- "timestamp=6-byte big-endian ms since Unix epoch (GMT); axes=int16 big-endian"
    meta$processing$sens_parser <- list(name = MJT_SENS_PARSER_NAME, version = MJT_DEVICE_PARSER_VERSION,
        upstream_reference = "sens.dk vendor spec", upstream_reference_version = upstream_spec_accessed,
        implementation_change = "Vectorised byte decoding replaces row-wise timestamp decoding; timestamp and axis definitions are unchanged.")
    meta <- set_calibration_provenance(meta, status = "fixed_scale_applied", scale_applied = TRUE, calibration_applied = FALSE,
        scale_source = "SENs vendor fixed binary scale", calibration_source = NA_character_, applied_by = MJT_SENS_PARSER_NAME,
        details = list(scale_g_per_lsb = as.numeric(scale_g_per_lsb)), notes = "Signed 16-bit axis counts are converted to g using the vendor fixed scale. No per-file offset, sensitivity, cross-axis, or temperature calibration coefficients are present in the supported SENs binary payload.",
        caveats = c("Calibration beyond the fixed scale is not applied by the SENs parser."))
    file_size <- meta$file$bytes  # bytes
    if (file_size%%RECORD_SIZE != 0)
        stop("File size is not a multiple of SENs record size (12 bytes).")
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    raw_data <- readBin(con, what = "raw", n = file_size)
    data_matrix <- matrix(raw_data, ncol = RECORD_SIZE, byrow = TRUE)
    decode_u8 <- function(i) as.numeric(data_matrix[, i])
    ts_num <- decode_u8(1L) * 256^5  # timestamp byte 1
    ts_num <- ts_num + decode_u8(2L) * 256^4  # timestamp byte 2
    ts_num <- ts_num + decode_u8(3L) * 256^3  # timestamp byte 3
    ts_num <- ts_num + decode_u8(4L) * 256^2  # timestamp byte 4
    ts_num <- ts_num + decode_u8(5L) * 256  # timestamp byte 5
    ts_num <- ts_num + decode_u8(6L)  # timestamp byte 6
    time <- as.POSIXct(ts_num/1000, origin = "1970-01-01", tz = "UTC")
    decode_axis <- function(high_i, low_i, scale) {
        value <- as.integer(data_matrix[, high_i]) * 256L + as.integer(data_matrix[, low_i])
        value[value >= 32768L] <- value[value >= 32768L] - 65536L
        value * scale
    }
    ax <- decode_axis(7L, 8L, scale_g_per_lsb)
    ay <- decode_axis(9L, 10L, scale_g_per_lsb)
    az <- decode_axis(11L, 12L, scale_g_per_lsb)
    res <- apply_time_policy(time, meta, tz_declared = "UTC", tz_parsed = "UTC", tz_source = "declared",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    x <- as_accel_tbl(time, ax, ay, az, meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# Optional CWA fallback parser ----
parse_axivity_cwa_ggir <- function(path, desiredtz = "UTC", interpolationType = 1, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, time_shift_s = 0, return = c("data",
        "bundle"), hash_sha256 = NULL) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    meta <- meta_min_template(path, "axivity_cwa", parser = "GGIRread", parser_version = as.character(utils::packageVersion("GGIRread")),
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "Axivity"
    meta$acquisition$device_model <- "AX3"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    meta$processing$decode_notes <- paste0("readAxivity(desiredtz=", desiredtz, ", interpolationType=",
        interpolationType, ")")
    last <- cwa_last_block(path)
    if (last < 0)
        stop("No CWA data blocks detected after header.")
    out <- GGIRread::readAxivity(filename = path, start = 0, end = last, desiredtz = desiredtz, interpolationType = interpolationType,
        progressBar = FALSE)
    d <- out$data
    h <- out$header
    time <- pick_col(d, c("timestamp", "time", "datetime"))
    ax <- pick_col(d, c("x", "X", "acc_x", "accx"))
    ay <- pick_col(d, c("y", "Y", "acc_y", "accy"))
    az <- pick_col(d, c("z", "Z", "acc_z", "accz"))
    if (!inherits(time, "POSIXct"))
        time <- as.POSIXct(time, tz = desiredtz)
    res <- apply_time_policy(time, meta, tz_declared = NA_character_, tz_parsed = desiredtz, tz_source = "user",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    if (is.list(h)) {
        if (!is.null(h$deviceId))
            meta$acquisition$device_id <- as.character(h$deviceId)
        if (!is.null(h$sampleRate))
            meta$acquisition$fs_nominal_hz <- suppressWarnings(as.numeric(h$sampleRate))
        if (!is.finite(meta$acquisition$full_scale_range_g) && !is.null(h$accelRange)) {
            meta$acquisition$full_scale_range_g <- pm_to_fullscale(suppressWarnings(as.numeric(h$accelRange)))
        }
    }
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    meta <- set_calibration_provenance(meta, status = "upstream_scale_applied_no_metronautica_calibration",
        scale_applied = TRUE, calibration_applied = FALSE, scale_source = "CWA accelScale/accelScaleCode via GGIRread::readAxivity",
        calibration_source = NA_character_, applied_by = "GGIRread::readAxivity", details = list(ggirread_version = as.character(utils::packageVersion("GGIRread")),
            interpolationType = interpolationType, sample_rate_header = if (is.list(h) && !is.null(h$sampleRate)) suppressWarnings(as.numeric(h$sampleRate)) else NA_real_,
            accel_range_header = if (is.list(h) && !is.null(h$accelRange)) suppressWarnings(as.numeric(h$accelRange)) else NA_real_),
        notes = "The GGIRread fallback applies the CWA acceleration scale from the file. Metronautica does not add separate offset/sensitivity calibration in this wrapper.",
        caveats = c("GGIRread::readAxivity has no Metronautica calibrate parameter in this path."))
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

parse_axivity_cwa <- function(path, desiredtz = "UTC", interpolationType = 1, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, time_shift_s = 0, return = c("data",
        "bundle"), hash_sha256 = NULL, use_ggir_fallback = TRUE) {
    return <- match.arg(return)
    fast <- tryCatch(parse_axivity_cwa_mjt(path = path, desiredtz = desiredtz, sensor_vendor = sensor_vendor,
        sensor_model = sensor_model, full_scale_range_g = full_scale_range_g, time_shift_s = time_shift_s,
        return = return, hash_sha256 = hash_sha256), error = function(e) e)
    if (!inherits(fast, "error"))
        return(fast)
    if (!isTRUE(use_ggir_fallback))
        stop(conditionMessage(fast))
    warning(MJT_AX3_CWA_PARSER_NAME, " could not decode this CWA file; falling back to GGIRread: ", conditionMessage(fast))
    parse_axivity_cwa_ggir(path = path, desiredtz = desiredtz, interpolationType = interpolationType,
        sensor_vendor = sensor_vendor, sensor_model = sensor_model, full_scale_range_g = full_scale_range_g,
        time_shift_s = time_shift_s, return = return, hash_sha256 = hash_sha256)
}

# Axivity CSV decoding ----
ax3_csv_clean_text <- function(x) {
    x <- as.character(x)
    x <- sub("^\357\273\277", "", x, useBytes = TRUE)  # strip UTF-8 BOM bytes
    x <- iconv(x, from = "", to = "UTF-8", sub = "")  # drop invalid byte sequences
    trimws(x)
}

ax3_csv_norm_name <- function(x) {
    gsub("[^a-z0-9]+", "", tolower(ax3_csv_clean_text(x)))
}

ax3_csv_sep <- function(header_line) {
    if (grepl("\t", header_line, fixed = TRUE))
        return("\t")
    ","
}

ax3_csv_numeric_like <- function(x) {
    suppressWarnings(!is.na(as.numeric(ax3_csv_clean_text(x))))
}

ax3_csv_time_like <- function(x) {
    x <- ax3_csv_clean_text(x)
    vapply(strsplit(x, ":", fixed = TRUE), function(p) {
        length(p) %in% c(2L, 3L) && all(ax3_csv_numeric_like(p))
    }, logical(1))
}

ax3_csv_header <- function(path, n = 20L) {
    lines <- tryCatch(readLines(path, n = n, warn = FALSE, encoding = "UTF-8-BOM"), error = function(e) character(0))
    lines <- ax3_csv_clean_text(lines)
    lines <- lines[nzchar(trimws(lines))]
    if (!length(lines))
        stop("AX3 CSV parse failed: file is empty or unreadable.")
    idx <- which(grepl("\\bTime\\b", lines, ignore.case = TRUE) & grepl("Accel-?X", lines, ignore.case = TRUE) &
        grepl("Accel-?Y", lines, ignore.case = TRUE) & grepl("Accel-?Z", lines, ignore.case = TRUE))[1]
    if (!is.na(idx)) {
        sep <- ax3_csv_sep(lines[idx])
        names_raw <- trimws(strsplit(lines[idx], sep, fixed = TRUE)[[1]])
        return(list(header_line = lines[idx], header_index = idx, sep = sep, names = names_raw, has_header = TRUE,
            layout = "headered"))
    }
    for (i in seq_along(lines)) {
        sep <- ax3_csv_sep(lines[i])
        fields <- trimws(strsplit(lines[i], sep, fixed = TRUE)[[1]])
        if (length(fields) >= 4L && ax3_csv_time_like(fields[1]) && all(ax3_csv_numeric_like(fields[2:4]))) {
            return(list(header_line = NA_character_, header_index = 0L, sep = sep, names = c("time",
                "ax_g", "ay_g", "az_g"), has_header = FALSE, layout = "headerless_time_xyz"))
        }
    }
    stop("AX3 CSV parse failed: could not identify a supported time/X/Y/Z layout.")
}

ax3_pick_name <- function(names, candidates) {
    norm <- ax3_csv_norm_name(names)
    target <- ax3_csv_norm_name(candidates)
    hit <- match(target, norm, nomatch = 0L)
    hit <- hit[hit > 0L]
    if (!length(hit))
        stop("Missing required AX3 CSV column: ", paste(candidates, collapse = " or "))
    names[hit[1]]
}

ax3_csv_parse_time <- function(x, tz_parsed = "UTC") {
    x <- trimws(as.character(x))
    fmt <- c("%Y-%m-%d %H:%M:%OS", "%Y/%m/%d %H:%M:%OS", "%d/%m/%Y %H:%M:%OS", "%m/%d/%Y %H:%M:%OS")
    for (f in fmt) {
        t <- as.POSIXct(x, format = f, tz = tz_parsed)
        if (!all(is.na(t))) {
            attr(t, "tzone") <- tz_parsed
            return(t)
        }
    }
    t <- suppressWarnings(as.POSIXct(x, tz = tz_parsed))
    attr(t, "tzone") <- tz_parsed
    t
}

ax3_csv_file_date <- function(path, tz_parsed = "UTC") {
    stem <- tools::file_path_sans_ext(basename(path))
    hits <- regmatches(stem, gregexpr("\\d{1,2}([-_])\\d{1,2}\\1\\d{2,4}", stem, perl = TRUE))[[1]]
    if (!length(hits) || all(is.na(hits)))
        return(ISOdatetime(1970, 1, 1, 0, 0, 0, tz = tz_parsed))
    for (token in rev(hits)) {
        token <- gsub("_", "-", token)
        parts <- strsplit(token, "-", fixed = TRUE)[[1]]
        if (length(parts) != 3L)
            next
        dd <- as.integer(parts[1])
        mm <- as.integer(parts[2])
        yy <- as.integer(parts[3])
        if (is.na(dd) || is.na(mm) || is.na(yy) || dd < 1L || dd > 31L || mm < 1L || mm > 12L)
            next
        if (yy < 100L)
            yy <- 2000L + yy
        return(ISOdatetime(yy, mm, dd, 0, 0, 0, tz = tz_parsed))
    }
    ISOdatetime(1970, 1, 1, 0, 0, 0, tz = tz_parsed)
}

ax3_csv_time_seconds <- function(x) {
    x <- ax3_csv_clean_text(x)
    parts <- strsplit(x, ":", fixed = TRUE)
    lens <- lengths(parts)
    secs <- rep(NA_real_, length(x))
    for (i in seq_along(parts)) {
        p <- parts[[i]]
        if (length(p) == 3L)
            secs[i] <- as.numeric(p[1]) * 3600 + as.numeric(p[2]) * 60 + as.numeric(p[3])
        if (length(p) == 2L)
            secs[i] <- as.numeric(p[1]) * 60 + as.numeric(p[2])
    }
    list(seconds = secs, components = lens)
}

ax3_csv_unwrap_seconds <- function(seconds, period_s) {
    out <- seconds
    if (length(out) < 2L)
        return(out)
    offset <- 0  # accumulated wrap offset
    prev <- out[1]
    for (i in 2:length(out)) {
        if (is.na(out[i]) || is.na(prev)) {
            prev <- out[i]
            next
        }
        if (out[i] < prev)
            offset <- offset + period_s
        prev <- out[i]
        out[i] <- out[i] + offset
    }
    out
}

ax3_csv_time_from_tokens <- function(tokens, path, tz_parsed = "UTC") {
    parsed <- ax3_csv_time_seconds(tokens)
    secs <- parsed$seconds
    if (all(is.na(secs)))
        stop("AX3 CSV parse failed: could not parse time-only column.")
    component_count <- stats::median(parsed$components[!is.na(parsed$components)], na.rm = TRUE)
    period_s <- if (is.finite(component_count) && component_count >= 3L)
        86400
    else 3600
    unwrapped <- ax3_csv_unwrap_seconds(secs, period_s = period_s)
    date_origin <- ax3_csv_file_date(path, tz_parsed = tz_parsed)
    if (!is.finite(as.numeric(date_origin)))
        date_origin <- ISOdatetime(1970, 1, 1, 0, 0, 0, tz = tz_parsed)
    n <- length(unwrapped)
    first_s <- unwrapped[which(!is.na(unwrapped))[1]]
    last_s <- tail(unwrapped[!is.na(unwrapped)], 1)
    if (n > 1L && is.finite(first_s) && is.finite(last_s) && last_s > first_s) {
        hz <- (n - 1)/(last_s - first_s)
        time <- as.POSIXct(as.numeric(date_origin) + first_s + (seq_len(n) - 1)/hz, origin = "1970-01-01",
            tz = tz_parsed)
        grid <- "generated_from_time_only_extent"
    }
    else {
        hz <- NA_real_
        time <- as.POSIXct(as.numeric(date_origin) + unwrapped, origin = "1970-01-01", tz = tz_parsed)
        grid <- "parsed_time_only_per_row"
    }
    list(time = time, hz = hz, timestamp_grid = grid, date_anchor = format(date_origin, "%Y-%m-%d", tz = tz_parsed),
        time_components = as.integer(component_count), date_from_filename = !identical(format(date_origin,
            "%Y-%m-%d", tz = tz_parsed), "1970-01-01"), wrap_period_s = period_s)
}

ax3_csv_last_nonempty_line <- function(path, block_size = 65536L) {
    file_size <- as.numeric(file.info(path)$size)  # bytes
    if (!is.finite(file_size) || file_size <= 0)
        return(NA_character_)
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    pos <- file_size
    raw_tail <- raw(0)
    while (pos > 0) {
        start <- max(0, pos - block_size)
        seek(con, where = start, origin = "start")
        chunk <- readBin(con, what = "raw", n = pos - start)
        raw_tail <- c(chunk, raw_tail)
        text <- rawToChar(raw_tail)
        lines <- unlist(strsplit(text, "\r\n|\n|\r", perl = TRUE), use.names = FALSE)
        lines <- lines[nzchar(trimws(lines))]
        if (length(lines) && start == 0)
            return(tail(lines, 1))
        if (length(lines) >= 2)
            return(tail(lines, 1))
        pos <- start
    }
    NA_character_
}

detect_axivity_csv <- function(path) {
    hdr <- tryCatch(ax3_csv_header(path), error = function(e) NULL)
    if (is.null(hdr))
        return(FALSE)
    if (!isTRUE(hdr$has_header) && identical(hdr$layout, "headerless_time_xyz"))
        return(TRUE)
    norm <- ax3_csv_norm_name(hdr$names)
    all(c("time", "accelxg", "accelyg", "accelzg") %in% norm)
}

parse_axivity_csv <- function(path, tz_parsed = "UTC", time_shift_s = 0, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, return = c("data", "bundle"), hash_sha256 = NULL,
    use_fast = TRUE) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    meta <- meta_min_template(path, "axivity_csv", parser = MJT_AX3_CSV_PARSER_NAME, parser_version = MJT_DEVICE_PARSER_VERSION,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "Axivity"
    meta$acquisition$device_model <- "AX3"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    device_id_guess <- sub("_.*$", "", tools::file_path_sans_ext(basename(path)))
    if (nzchar(device_id_guess))
        meta$acquisition$device_id <- device_id_guess
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)

    hdr <- ax3_csv_header(path)
    if (isTRUE(hdr$has_header)) {
        time_col <- ax3_pick_name(hdr$names, c("Time", "Timestamp", "DateTime", "Date Time"))
        x_col <- ax3_pick_name(hdr$names, c("Accel-X (g)", "Accel X (g)", "Accelerometer X", "X", "x",
            "ax_g", "ax"))
        y_col <- ax3_pick_name(hdr$names, c("Accel-Y (g)", "Accel Y (g)", "Accelerometer Y", "Y", "y",
            "ay_g", "ay"))
        z_col <- ax3_pick_name(hdr$names, c("Accel-Z (g)", "Accel Z (g)", "Accelerometer Z", "Z", "z",
            "az_g", "az"))
        accel_cols <- c(x_col, y_col, z_col)
        time_select <- time_col
    }
    else {
        time_col <- "time"
        x_col <- "ax_g"
        y_col <- "ay_g"
        z_col <- "az_g"
        accel_cols <- c(x_col, y_col, z_col)
        time_select <- 1L
    }

    if (isTRUE(use_fast) && requireNamespace("data.table", quietly = TRUE)) {
        d <- if (isTRUE(hdr$has_header)) {
            data.table::fread(input = path, sep = hdr$sep, header = TRUE, skip = hdr$header_index - 1L,
                select = accel_cols, data.table = FALSE, showProgress = FALSE)
        }
        else {
            data.table::fread(input = path, sep = hdr$sep, header = FALSE, select = c(2L, 3L, 4L), data.table = FALSE,
                showProgress = FALSE)
        }
        reader_name <- "data.table::fread"
    }
    else {
        d <- if (hdr$sep == "\t") {
            utils::read.table(path, header = isTRUE(hdr$has_header), sep = "\t", quote = "", comment.char = "",
                stringsAsFactors = FALSE, check.names = FALSE, skip = if (isTRUE(hdr$has_header))
                  hdr$header_index - 1L
                else 0L)
        }
        else {
            utils::read.csv(path, header = isTRUE(hdr$has_header), stringsAsFactors = FALSE, check.names = FALSE,
                skip = if (isTRUE(hdr$has_header))
                  hdr$header_index - 1L
                else 0L)
        }
        if (!isTRUE(hdr$has_header))
            names(d) <- hdr$names
        names(d) <- trimws(names(d))
        d <- d[, accel_cols, drop = FALSE]
        reader_name <- if (hdr$sep == "\t")
            "utils::read.table"
        else "utils::read.csv"
    }
    names(d) <- trimws(names(d))
    if (!isTRUE(hdr$has_header))
        names(d) <- accel_cols
    ax <- d[[x_col]]
    ay <- d[[y_col]]
    az <- d[[z_col]]
    n <- length(ax)
    if (!n)
        stop("AX3 CSV parse failed: no acceleration samples were read.")

    time_provenance <- list(layout = hdr$layout, date_from_filename = FALSE, date_anchor = NA_character_)
    if (isTRUE(hdr$has_header)) {
        prefix <- readLines(path, n = max(2L, hdr$header_index + 1L), warn = FALSE)
        first_data_line <- prefix[hdr$header_index + 1L] %m_parser_or% NA_character_
        first_fields <- if (!is.na(first_data_line))
            trimws(strsplit(first_data_line, hdr$sep, fixed = TRUE)[[1]])
        else character(0)
        first_time <- ax3_csv_parse_time(first_fields[match(time_col, hdr$names)] %m_parser_or% NA_character_,
            tz_parsed)  # first timestamp
        last_line <- ax3_csv_last_nonempty_line(path)
        last_fields <- if (!is.na(last_line))
            trimws(strsplit(last_line, hdr$sep, fixed = TRUE)[[1]])
        else character(0)
        last_time <- ax3_csv_parse_time(last_fields[match(time_col, hdr$names)] %m_parser_or% NA_character_,
            tz_parsed)  # last timestamp

        regular_time <- n > 1L && !is.na(first_time) && !is.na(last_time) && as.numeric(last_time) >
            as.numeric(first_time)
        if (regular_time) {  # synthesize regular timestamp grid
            hz <- (n - 1)/as.numeric(difftime(last_time, first_time, units = "secs"))
            time <- as.POSIXct(as.numeric(first_time) + (seq_len(n) - 1)/hz, origin = "1970-01-01", tz = tz_parsed)
            timestamp_grid <- "generated_from_first_and_last_timestamp"
        }
        else {  # fallback to row-wise timestamp parse
            time_data <- if (isTRUE(use_fast) && requireNamespace("data.table", quietly = TRUE)) {
                data.table::fread(input = path, sep = hdr$sep, header = TRUE, skip = hdr$header_index -
                  1L, select = time_col, data.table = FALSE, showProgress = FALSE)[[time_col]]
            }
            else {
                all_data <- if (hdr$sep == "\t") {
                  utils::read.table(path, header = TRUE, sep = "\t", quote = "", comment.char = "", stringsAsFactors = FALSE,
                    check.names = FALSE, skip = hdr$header_index - 1L)
                }
                else {
                  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, skip = hdr$header_index -
                    1L)
                }
                names(all_data) <- trimws(names(all_data))
                all_data[[time_col]]
            }
            time <- ax3_csv_parse_time(time_data, tz_parsed)  # parse all timestamps
            if (all(is.na(time)))
                stop("AX3 CSV parse failed: could not parse Time column.")
            hz <- derive_fs(time)
            timestamp_grid <- "parsed_per_row"
        }
    }
    else {
        time_data <- if (isTRUE(use_fast) && requireNamespace("data.table", quietly = TRUE)) {
            data.table::fread(input = path, sep = hdr$sep, header = FALSE, select = time_select, data.table = FALSE,
                showProgress = FALSE)[[1]]
        }
        else {
            all_data <- if (hdr$sep == "\t") {
                utils::read.table(path, header = FALSE, sep = "\t", quote = "", comment.char = "", stringsAsFactors = FALSE,
                  check.names = FALSE)
            }
            else {
                utils::read.csv(path, header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)
            }
            all_data[[1]]
        }
        time_result <- ax3_csv_time_from_tokens(time_data, path = path, tz_parsed = tz_parsed)
        time <- time_result$time  # timestamps
        hz <- time_result$hz
        if (!is.finite(hz))
            hz <- derive_fs(time)
        timestamp_grid <- time_result$timestamp_grid
        time_provenance <- time_result[setdiff(names(time_result), c("time", "hz"))]
        meta$file$warnings <- c(meta$file$warnings %m_parser_or% character(0), "AX3 CSV did not contain full date-time stamps; timestamps were reconstructed from the filename date and the time-only first column.")
    }

    res <- apply_time_policy(time, meta, tz_declared = NA_character_, tz_parsed = tz_parsed, tz_source = "user",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- as.numeric(hz)
    meta$processing$decode_notes <- paste0("AX3 CSV export; layout=", hdr$layout, "; sep=", if (hdr$sep ==
        "\t")
        "tab"
    else "comma", "; reader=", reader_name, "; timestamp_grid=", timestamp_grid)
    meta$processing$ax3_csv_parser <- list(name = MJT_AX3_CSV_PARSER_NAME, version = MJT_DEVICE_PARSER_VERSION,
        upstream_reference = "Axivity AX3 CSV exports containing time plus X/Y/Z acceleration columns in g",
        implementation_change = paste("Detects headered Time + Accel-X/Y/Z exports and headerless time/X/Y/Z exports.",
            "For regular exports, timestamps are generated from the available time extent to avoid duplicate or row-wise date parsing."))
    meta <- set_calibration_provenance(meta, status = "export_scaled_no_metronautica_calibration", scale_applied = TRUE,
        calibration_applied = FALSE, scale_source = "AX3 CSV exported acceleration columns in g", calibration_source = NA_character_,
        applied_by = "AX3 CSV export / source file", details = list(timestamp_grid = timestamp_grid,
            time_provenance = time_provenance, csv_layout = hdr$layout, sample_rate_hz = as.numeric(hz),
            acceleration_columns = as.list(accel_cols)), notes = "Metronautica reads AX3 CSV acceleration values as already exported in g. It does not apply additional scale, offset, temperature, or autocalibration correction.",
        caveats = c("Use the original CWA path or a validated calibration workflow when binary-level scale provenance or autocalibration is required.",
            if (!isTRUE(hdr$has_header)) "Headerless AX3 CSV files may not contain a full date-time column; absolute timestamps are reconstructed from the filename date when possible." else NULL))
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# Preserve modern GT3X native precision.
# Decode counts before file scaling.
# Preserve exact integer samples.
m_gt3x_native_data <- function(path, info) {
    version <- utils::packageVersion("read.gt3x")
    decoder <- get0("parseGT3X", envir = asNamespace("read.gt3x"), inherits = FALSE)
    decoder <- check_gt3x_bounded_interface(version, decoder)
    scale <- as.numeric(info[["Acceleration Scale"]])
    fs <- as.numeric(info[["Sample Rate"]])
    start <- as.numeric(info[["Start Date"]])
    if (any(!is.finite(c(scale, fs, start))) || length(c(scale, fs, start)) != 3L || scale <= 0 || fs <=
        0)
        stop("Native GT3X precision requires valid scale, frequency and recording start metadata.")
    entries <- utils::unzip(path, list = TRUE)$Name
    if (!"log.bin" %in% entries)
        stop("Native precision currently supports modern log.bin GT3X containers; use precision='legacy_3dp' for older formats.")
    sample_count <- utils::getFromNamespace("get_n_samples", "read.gt3x")(info)
    if (length(sample_count) != 1L || !is.finite(sample_count) || sample_count <= 0 || sample_count >=
        .Machine$integer.max)
        stop("Unsupported GT3X sample count.")
    work <- tempfile("metronautica_native_")
    dir.create(work)
    on.exit(unlink(work, recursive = TRUE), add = TRUE)
    utils::unzip(path, files = "log.bin", exdir = work, junkpaths = TRUE)
    a <- decoder(file.path(work, "log.bin"), max_samples = as.integer(sample_count), scale_factor = 1,
        sample_rate = fs, start_time = start, verbose = FALSE, impute_zeroes = FALSE)
    ti <- attr(a, "time_index")
    if (length(ti) != nrow(a))
        stop("Native GT3X decoder returned inconsistent timestamps.")
    data.frame(time = as.POSIXct(start + ti/100, origin = "1970-01-01", tz = "GMT"), X = a[, "X"]/scale,
        Y = a[, "Y"]/scale, Z = a[, "Z"]/scale)
}

# ActiGraph GT3X parser ----
parse_act_gt3x <- function(path, imputeZeroes = FALSE, add_light = FALSE, cleanup = FALSE, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, time_shift_s = 0, return = c("data",
        "bundle"), hash_sha256 = NULL, precision = c("native", "legacy_3dp")) {
    return <- match.arg(return)
    precision <- match.arg(precision)
    stopifnot(file.exists(path))
    gt3x_version <- as.character(utils::packageVersion("read.gt3x"))
    meta <- meta_min_template(path, "actigraph_gt3x", parser = "read.gt3x", parser_version = gt3x_version,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "ActiGraph"
    meta$acquisition$device_model <- "GT3X/GT3X+/GT9X"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    meta$processing$decode_notes <- paste0("read.gt3x(imputeZeroes=", imputeZeroes, ", add_light=", add_light,
        ", cleanup=", cleanup, ")")
    meta$processing$actigraph_gt3x_parser <- list(name = "read.gt3x", version = gt3x_version, upstream_reference = "THLfi/read.gt3x",
        implementation_change = "Metronautica keeps the upstream read.gt3x decoder and wraps output into the app raw signal schema.")
    info <- tryCatch(read.gt3x::parse_gt3x_info(path), error = function(e) NULL)
    acceleration_scale <- NA_real_  # read.gt3x scale factor
    if (is.list(info)) {
        if (!is.null(info$`Serial Number`))
            meta$acquisition$device_id <- as.character(info$`Serial Number`)
        if (!is.null(info$`Sample Rate`))
            meta$acquisition$fs_nominal_hz <- suppressWarnings(as.numeric(info$`Sample Rate`))
        if (!is.null(info$`Acceleration Scale`))
            acceleration_scale <- suppressWarnings(as.numeric(info$`Acceleration Scale`))  # scale
    }
    meta <- set_calibration_provenance(meta, status = "upstream_scale_applied_no_metronautica_calibration",
        scale_applied = TRUE, calibration_applied = FALSE, scale_source = "GT3X info.txt Acceleration Scale used by read.gt3x",
        calibration_source = NA_character_, applied_by = "read.gt3x::read.gt3x", details = list(acceleration_scale = acceleration_scale,
            imputeZeroes = isTRUE(imputeZeroes), add_light = isTRUE(add_light), cleanup = isTRUE(cleanup)),
        notes = "read.gt3x converts GT3X acceleration counts to g using the file scale factor. Metronautica does not apply an additional calibration correction.",
        caveats = c("read.gt3x does not expose a Metronautica calibration parameter for offset/sensitivity correction."))
    if (precision == "native") {
        if (isTRUE(imputeZeroes) || isTRUE(add_light))
            stop("Native precision retains acceleration samples without imputation/light extraction; use precision='legacy_3dp' for the upstream options.",
                call. = FALSE)
        d <- m_gt3x_native_data(path, info)
    }
    else {
        d <- read.gt3x::read.gt3x(path = path, asDataFrame = TRUE, imputeZeroes = imputeZeroes, add_light = add_light,
            cleanup = cleanup, verbose = FALSE)
    }
    meta$processing$precision <- list(mode = precision, acceleration_rounding_decimals = if (precision ==
        "native") NULL else 3L, conversion = if (precision == "native") "integer samples divided by native Acceleration Scale" else "upstream read.gt3x scaled and rounded output",
        imputed = isTRUE(imputeZeroes))
    if (is.list(info) && !is.null(info[["Start Date"]]))
        meta$acquisition$recording_start_utc <- as.POSIXct(as.numeric(info[["Start Date"]]) + time_shift_s,
            origin = "1970-01-01", tz = "UTC")
    meta$processing$decode_notes <- paste(meta$processing$decode_notes, "precision:", precision, "Device clock labels retain the existing upstream time convention; no timezone correction is inferred.")
    time <- pick_col(d, c("time", "timestamp", "datetime"))
    ax <- pick_col(d, c("X", "x", "acc_x", "accx"))
    ay <- pick_col(d, c("Y", "y", "acc_y", "accy"))
    az <- pick_col(d, c("Z", "z", "acc_z", "accz"))
    if (!inherits(time, "POSIXct"))
        time <- as.POSIXct(time, tz = "UTC")
    res <- apply_time_policy(time, meta, tz_declared = NA_character_, tz_parsed = "UTC", tz_source = "unknown",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

detect_act_leap_csv <- function(path, n = 30) {
    stopifnot(file.exists(path))
    hdr <- tryCatch(readLines(path, n = n, warn = FALSE), error = function(e) character(0))
    if (!length(hdr))
        return(FALSE)
    any(grepl("ActiGraph LEAP", hdr, ignore.case = TRUE)) && any(grepl("Data File Created", hdr, ignore.case = TRUE))
}

# LEAP AGSD container decoding ----
detect_act_leap_agsd <- function(path) {
    stopifnot(file.exists(path))
    if (tolower(tools::file_ext(path)) != "agsd")
        return(FALSE)
    z <- tryCatch(utils::unzip(path, list = TRUE), error = function(e) NULL)
    if (is.null(z) || !nrow(z))
        return(FALSE)
    all(c("sensordata.bin", "info.json", "manifest.json") %in% z$Name)
}

leap_agsd_entry_size <- function(path, entry) {
    z <- utils::unzip(path, list = TRUE)
    hit <- z[z$Name == entry, , drop = FALSE]
    if (!nrow(hit))
        stop("AGSD parse failed: missing ", entry, ".")
    as.numeric(hit$Length[1])
}

leap_agsd_read_text <- function(path, entry) {
    tmp <- tempfile("metronautica_agsd_")
    dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
    out <- utils::unzip(path, files = entry, exdir = tmp, junkpaths = TRUE, overwrite = TRUE)
    paste(readLines(out[1], warn = FALSE), collapse = "\n")
}

leap_agsd_read_raw <- function(path, entry) {
    n <- leap_agsd_entry_size(path, entry)
    tmp <- tempfile("metronautica_agsd_")
    dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
    out <- utils::unzip(path, files = entry, exdir = tmp, junkpaths = TRUE, overwrite = TRUE)
    con <- file(out[1], open = "rb")
    on.exit(close(con), add = TRUE)
    x <- readBin(con, what = "raw", n = n)
    if (length(x) != n)
        stop("AGSD parse failed: incomplete read of ", entry, ".")
    x
}

leap_agsd_u16 <- function(x, i) {
    as.integer(x[i]) + as.integer(x[i + 1L]) * 256L
}

leap_agsd_u32 <- function(x, i) {
    as.numeric(x[i]) + as.numeric(x[i + 1L]) * 256 + as.numeric(x[i + 2L]) * 65536 + as.numeric(x[i +
        3L]) * 16777216
}

leap_agsd_records <- function(sensor_raw) {
    n <- length(sensor_raw)
    max_records <- max(1L, ceiling(n/10))
    pos <- numeric(max_records)
    typ <- integer(max_records)
    ts <- numeric(max_records)
    len <- integer(max_records)
    payload_start <- numeric(max_records)
    checksum <- integer(max_records)
    i <- 1L
    p <- 1L
    while (p <= n) {
        if (p + 9L > n)
            stop("AGSD parse failed: truncated record header at byte ", p - 1L, ".")
        if (as.integer(sensor_raw[p]) != 0x1E)
            stop("AGSD parse failed: expected record marker 0x1E at byte ", p - 1L, ".")
        record_len <- leap_agsd_u16(sensor_raw, p + 6L)
        next_p <- p + 8L + record_len + 2L
        if (next_p - 1L > n)
            stop("AGSD parse failed: record at byte ", p - 1L, " extends past end of sensordata.bin.")
        if (i > length(pos)) {
            grow <- length(pos)
            pos <- c(pos, numeric(grow))
            typ <- c(typ, integer(grow))
            ts <- c(ts, numeric(grow))
            len <- c(len, integer(grow))
            payload_start <- c(payload_start, numeric(grow))
            checksum <- c(checksum, integer(grow))
        }
        pos[i] <- p
        typ[i] <- as.integer(sensor_raw[p + 1L])
        ts[i] <- leap_agsd_u32(sensor_raw, p + 2L)
        len[i] <- record_len
        payload_start[i] <- p + 8L
        checksum[i] <- leap_agsd_u16(sensor_raw, p + 8L + record_len)
        i <- i + 1L
        p <- next_p
    }
    keep <- seq_len(i - 1L)
    list(pos = pos[keep], type = typ[keep], timestamp = ts[keep], length = len[keep], payload_start = payload_start[keep],
        checksum = checksum[keep])
}

# Validate supported LEAP coefficients ----
leap_agsd_calibration <- function(cal, fs) {
    if (!identical(as.integer(fs), 128L) || !identical(as.integer(cal$calibrationMethod), 2L))
        stop("Corrected LEAP conversion is validated only for 128 Hz / calibrationMethod 2")
    suffix <- paste0("_", as.integer(fs))
    get_num <- function(name) {
        value <- cal[[paste0(name, suffix)]]
        if (is.null(value) || !is.finite(as.numeric(value)))
            stop("AGSD parse failed: missing calibration field ", name, suffix, ".")
        as.numeric(value)
    }
    offset <- c(get_num("offsetX"), get_num("offsetY"), get_num("offsetZ"))
    sensitivity <- matrix(c(get_num("sensitivityXX"), get_num("sensitivityXY"), get_num("sensitivityXZ"),
        get_num("sensitivityXY"), get_num("sensitivityYY"), get_num("sensitivityYZ"), get_num("sensitivityXZ"),
        get_num("sensitivityYZ"), get_num("sensitivityZZ")), nrow = 3L, byrow = TRUE)
    # Apply validated stored coefficients.
    m <- 100/(25000 + sensitivity) - 0.004
    diag(m) <- 100/diag(sensitivity)
    if (any(!is.finite(m)))
        stop("Invalid LEAP calibration coefficients")
    list(offset = offset, sensitivity = sensitivity, inverse = m/100)
}

# Decode LEAP sample payloads ----
leap_agsd_decode_payload <- function(sensor_raw, starts, payload_len, fs, calibration, chunk_records = 6000L) {
    n_records <- length(starts)
    n_samples <- n_records * fs
    ax <- numeric(n_samples)
    ay <- numeric(n_samples)
    az <- numeric(n_samples)
    sample_offset <- 0L
    sign12 <- function(v) {
        v <- as.integer(v)
        v[v >= 2048L] <- v[v >= 2048L] - 4096L
        v
    }
    inv <- calibration$inverse
    off <- calibration$offset
    for (start_i in seq.int(1L, n_records, by = chunk_records)) {
        end_i <- min(n_records, start_i + chunk_records - 1L)
        rec_count <- end_i - start_i + 1L
        payload <- raw(rec_count * payload_len)
        out <- 1L
        for (record_i in seq.int(start_i, end_i)) {
            s <- starts[record_i]
            payload[out:(out + payload_len - 1L)] <- sensor_raw[s:(s + payload_len - 1L)]
            out <- out + payload_len
        }
        b <- matrix(as.integer(payload), ncol = 9L, byrow = TRUE)
        v1 <- sign12(b[, 1L] * 16L + floor(b[, 2L]/16L))
        v2 <- sign12((b[, 2L]%%16L) * 256L + b[, 3L])
        v3 <- sign12(b[, 4L] * 16L + floor(b[, 5L]/16L))
        v4 <- sign12((b[, 5L]%%16L) * 256L + b[, 6L])
        v5 <- sign12(b[, 7L] * 16L + floor(b[, 8L]/16L))
        v6 <- sign12((b[, 8L]%%16L) * 256L + b[, 9L])
        chunk_n <- length(v1) * 2L
        rx <- numeric(chunk_n)
        ry <- numeric(chunk_n)
        rz <- numeric(chunk_n)
        odd <- seq.int(1L, chunk_n, by = 2L)
        even <- odd + 1L
        rx[odd] <- v1
        ry[odd] <- v2
        rz[odd] <- v3
        rx[even] <- v4
        ry[even] <- v5
        rz[even] <- v6
        dx <- rx - off[1L]
        dy <- ry - off[2L]
        dz <- rz - off[3L]
        idx <- seq.int(sample_offset + 1L, sample_offset + chunk_n)
        ax[idx] <- 100 * (inv[1L, 1L] * dx + inv[1L, 2L] * dy + inv[1L, 3L] * dz)
        ay[idx] <- 100 * (inv[2L, 1L] * dx + inv[2L, 2L] * dy + inv[2L, 3L] * dz)
        az[idx] <- 100 * (inv[3L, 1L] * dx + inv[3L, 2L] * dy + inv[3L, 3L] * dz)
        sample_offset <- sample_offset + chunk_n
    }
    list(ax = ax, ay = ay, az = az)
}

# LEAP AGSD parser ----
parse_act_leap_agsd <- function(path, tz_parsed = "UTC", time_shift_s = 0, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, return = c("data", "bundle"), hash_sha256 = NULL,
    ...) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    if (!detect_act_leap_agsd(path))
        stop("AGSD parse failed: file is not a recognised ActiGraph LEAP AGSD container.")
    info <- jsonlite::fromJSON(leap_agsd_read_text(path, "info.json"), simplifyVector = TRUE)
    if (!identical(info$deviceType, "LEAP v2") || info$dataVersion != 3L || !identical(info$firmware,
        "2.1.0.106"))
        stop("LEAP configuration outside validated corrected-parser scope")
    cal <- jsonlite::fromJSON(leap_agsd_read_text(path, "activityCalibration.json"), simplifyVector = TRUE)
    fs <- as.integer(info$sampleRate %m_parser_or% NA_integer_)
    if (!is.finite(fs) || fs <= 0L || fs%%2L != 0L)
        stop("AGSD parse failed: unsupported sample rate: ", fs, ".")
    payload_len <- as.integer(fs * 9L/2L)
    if (!is.finite(payload_len) || payload_len <= 0L || payload_len%%9L != 0L)
        stop("AGSD parse failed: unsupported payload length for sample rate ", fs, ".")
    sensor_raw <- leap_agsd_read_raw(path, "sensordata.bin")
    records <- leap_agsd_records(sensor_raw)
    data_records <- which(records$type == 0x1B)
    if (!length(data_records))
        stop("AGSD parse failed: no accelerometer records (type 0x1B) were found.")
    if (any(records$length[data_records] != payload_len)) {
        bad <- unique(records$length[data_records][records$length[data_records] != payload_len])
        stop("AGSD parse failed: unsupported accelerometer payload length(s): ", paste(bad, collapse = ", "),
            ".")
    }
    calibration <- leap_agsd_calibration(cal, fs)
    decoded <- leap_agsd_decode_payload(sensor_raw, records$payload_start[data_records], payload_len,
        fs, calibration)
    rec_ts <- records$timestamp[data_records]
    sample_offsets <- rep(seq.int(0L, fs - 1L)/fs, times = length(data_records))
    time <- as.POSIXct(rep(rec_ts, each = fs) + sample_offsets, origin = "1970-01-01", tz = tz_parsed)
    meta <- meta_min_template(path, "actigraph_leap_agsd", parser = MJT_LEAP_AGSD_PARSER_NAME, parser_version = MJT_DEVICE_PARSER_VERSION,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "ActiGraph"
    meta$acquisition$device_model <- info$deviceType %m_parser_or% "LEAP"
    meta$acquisition$device_id <- info$serialNumber %m_parser_or% NA_character_
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    meta$acquisition$fs_nominal_hz <- fs
    meta$acquisition$full_scale_range_g <- if (is.finite(full_scale_range_g) && full_scale_range_g >
        0) {
        as.numeric(full_scale_range_g)
    }
    else if (!is.null(info$accelerationMin) && !is.null(info$accelerationMax)) {
        abs(as.numeric(info$accelerationMax) - as.numeric(info$accelerationMin))
    }
    else {
        NA_real_
    }
    res <- apply_time_policy(time, meta, tz_declared = info$timeZone %m_parser_or% NA_character_, tz_parsed = tz_parsed,
        tz_source = "container_epoch", time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- fs
    meta$processing$decode_notes <- paste("AGSD ZIP-style LEAP container; sensordata.bin records decoded as marker/type/timestamp/length/payload/check records.",
        "Type 0x1B accelerometer payloads are decoded as 9-byte groups containing two samples of three signed 12-bit axes.",
        "Activity calibration matrix from activityCalibration.json is applied at the recorded sample rate.")
    meta$processing$leap_agsd_parser <- list(name = MJT_LEAP_AGSD_PARSER_NAME, version = MJT_DEVICE_PARSER_VERSION,
        upstream_reference = "ActiGraph LEAP AGSD container inferred from paired AGSD and ActiLife RAW CSV export",
        implementation_change = paste("Decodes the AGSD sensordata.bin record stream directly instead of requiring the 10x larger ActiLife RAW CSV export.",
            "Validated on the provided LEAP v2 sample against ActiLife v7.1.0 RAW CSV output."), record_counts = as.list(table(sprintf("0x%02X",
            records$type))), accelerometer_records = length(data_records), accelerometer_payload_bytes = payload_len,
        calibration_rate_hz = fs, firmware = info$firmware %m_parser_or% NA_character_, data_version = info$dataVersion %m_parser_or%
            NA_integer_, calibration_is_calibrated = cal$isCalibrated %m_parser_or% NA)
    sensitivity_rows <- matrix_row_lists(calibration$sensitivity, names = c("x", "y", "z"))
    names(sensitivity_rows) <- c("x", "y", "z")
    meta <- set_calibration_provenance(meta, status = "calibration_matrix_applied", scale_applied = TRUE,
        calibration_applied = TRUE, scale_source = "AGSD signed 12-bit packed counts with activityCalibration.json sensitivity matrix",
        calibration_source = "activityCalibration.json", applied_by = MJT_LEAP_AGSD_PARSER_NAME, details = list(calibration_rate_hz = fs,
            offset_counts = named_numeric_list(calibration$offset, names = c("x", "y", "z")), sensitivity_matrix = sensitivity_rows,
            output_formula = "g = 100 * inverse(sensitivity_matrix) %*% (raw_counts - offset_counts)",
            source_reports_calibrated = cal$isCalibrated %m_parser_or% NA, acceleration_min = info$accelerationMin %m_parser_or%
                NA, acceleration_max = info$accelerationMax %m_parser_or% NA), notes = "The direct LEAP AGSD parser applies the sample-rate-specific activity calibration coefficients before returning g values.",
        caveats = if (identical(cal$isCalibrated, FALSE)) {
            c("activityCalibration.json reports isCalibrated=false; coefficients were still applied because they reproduce ActiLife RAW CSV values for the validated sample.")
        }
        else {
            character(0)
        })
    if (identical(cal$isCalibrated, FALSE)) {
        meta$file$warnings <- c(meta$file$warnings, "AGSD activityCalibration.json reports isCalibrated=false; ActiLife-equivalent calibration coefficients were still applied.")
    }
    x <- as_accel_tbl(time, decoded$ax, decoded$ay, decoded$az, meta)
    m <- meta
    m$processing$decode_notes <- "AGSD signed 12-bit counts; shifted-reciprocal calibration; full-precision g; packet-relative 128 Hz nominal timestamps; gaps not filled."
    m$processing$leap_agsd_parser$implementation_change <- "Corrected coefficient decoding validated against 15 dynamic and one static ActiLife 7.1.0 exports at three-decimal precision."
    m$processing$leap_agsd_parser$version <- "0.0.5-agsd-correction-1"
    m$processing$calibration$details$output_formula <- "g=M*(counts-offset); Mii=100/sii; Mij=100/(25000+sij)-0.004"
    m$processing$calibration$details$sensitivity_matrix <- NULL
    m$processing$calibration$notes <- "Stored coefficients applied without export rounding. Physical calibration accuracy and the meaning of isCalibrated are not independently established."
    m$processing$calibration$caveats <- "Validated scope: LEAP v2, dataVersion 3, firmware 2.1.0.106, 128 Hz, calibrationMethod 2."
    m$file$warnings <- m$file$warnings[!grepl("ActiLife-equivalent", m$file$warnings, fixed = TRUE)]
    if (identical(m$processing$leap_agsd_parser$calibration_is_calibrated, FALSE))
        m$file$warnings <- c(m$file$warnings, "Source reports isCalibrated=false; retained verbatim, not interpreted as calibration traceability.")
    dt <- diff(as.numeric(x$time))
    gaps <- which(dt > 1.5/128)
    m$processing$leap_agsd_parser$recording_gaps <- list(count = length(gaps), missing_samples = sum(pmax(0,
        round(dt[gaps] * 128) - 1)), fill = "none")
    meta <- m
    attr(x, "meta") <- meta

    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# LEAP CSV decoding ----
leap_csv_header_prefix <- function(path, n = 200L) {
    x <- tryCatch(readLines(path, n = n, warn = FALSE), error = function(e) character(0))
    if (!length(x))
        stop("LEAP CSV parse failed: file is empty or unreadable.")
    x
}

leap_csv_sep <- function(header_line) {
    if (grepl(",", header_line, fixed = TRUE))
        return(",")
    if (grepl("\t", header_line, fixed = TRUE))
        return("\t")
    ","
}

leap_split_line <- function(line, sep) {
    strsplit(line, sep, fixed = TRUE)[[1]]
}

leap_pick_name <- function(names, candidates) {
    hit <- intersect(candidates, names)
    if (!length(hit))
        stop("Missing required LEAP CSV column: ", paste(candidates, collapse = " or "))
    hit[1]
}

leap_parse_timestamp <- function(x, tz_parsed) {
    as.POSIXct(trimws(x), format = "%d/%m/%Y %H:%M:%OS", tz = tz_parsed)
}

leap_last_nonempty_line <- function(path, block_size = 65536L) {
    file_size <- as.numeric(file.info(path)$size)
    if (!is.finite(file_size) || file_size <= 0)
        return(NA_character_)
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    pos <- file_size
    raw_tail <- raw(0)
    while (pos > 0) {
        start <- max(0, pos - block_size)
        seek(con, where = start, origin = "start")
        chunk <- readBin(con, what = "raw", n = pos - start)
        raw_tail <- c(chunk, raw_tail)
        text <- rawToChar(raw_tail)
        lines <- unlist(strsplit(text, "\r\n|\n|\r", perl = TRUE), use.names = FALSE)
        lines <- lines[nzchar(trimws(lines))]
        if (length(lines) && start == 0)
            return(tail(lines, 1))
        if (length(lines) >= 2)
            return(tail(lines, 1))
        pos <- start
    }
    NA_character_
}

leap_preamble_value <- function(pre, pattern) {
    hit <- grep(pattern, pre, ignore.case = TRUE, value = TRUE)
    if (!length(hit))
        return(NA_character_)
    trimws(sub(pattern, "", hit[1], ignore.case = TRUE, perl = TRUE))
}

# LEAP CSV parser ----
parse_act_leap_csv <- function(path, tz_parsed = "UTC", time_shift_s = 0, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, return = c("data", "bundle"), hash_sha256 = NULL,
    use_fast = TRUE) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    meta <- meta_min_template(path, "actigraph_leap_csv", parser = MJT_LEAP_CSV_PARSER_NAME, parser_version = MJT_DEVICE_PARSER_VERSION,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "ActiGraph"
    meta$acquisition$device_model <- "LEAP"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    lines <- leap_csv_header_prefix(path)
    timestamp_hdr_idx <- which(grepl("^[[:space:]]*(Timestamp|time|datetime)\\b", lines, ignore.case = TRUE,
        perl = TRUE))  # timestamp header
    accel_hdr_idx <- which(grepl("^[[:space:]]*Accelerometer[[:space:]._-]*X\\b", lines, ignore.case = TRUE,  # timestamp-less LEAP raw header
        perl = TRUE) & grepl("Accelerometer[[:space:]._-]*Y\\b", lines, ignore.case = TRUE, perl = TRUE) &
        grepl("Accelerometer[[:space:]._-]*Z\\b", lines, ignore.case = TRUE, perl = TRUE))
    hdr_idx <- if (length(timestamp_hdr_idx))
        timestamp_hdr_idx[1]
    else accel_hdr_idx[1]  # prefer timestamp header
    if (!length(hdr_idx) || is.na(hdr_idx)) {
        stop("LEAP CSV parse failed: could not find a Timestamp or Accelerometer X/Y/Z header line.")
    }
    pre <- if (hdr_idx[1] > 1)
        lines[seq_len(hdr_idx[1] - 1)]
    else character(0)
    banner <- pre[1] %m_parser_or% ""
    actilife_ver <- sub(".*\\bActiLife[[:space:]]*v([0-9]+\\.[0-9]+\\.[0-9]+)\\b.*", "\\1", banner, ignore.case = TRUE,
        perl = TRUE)
    if (!identical(actilife_ver, banner) && nzchar(actilife_ver))
        meta$processing$actilife_export_version <- paste0("v", actilife_ver)
    hz <- suppressWarnings(as.numeric(sub(".*\\bat[[:space:]]*([0-9]+)[[:space:]]*Hz\\b.*", "\\1", banner,
        ignore.case = TRUE, perl = TRUE)))
    if (is.finite(hz))
        meta$acquisition$fs_nominal_hz <- hz
    serial <- leap_preamble_value(pre, "^Serial Number:[[:space:]]*")
    if (!is.na(serial) && nzchar(serial))
        meta$acquisition$device_id <- as.character(serial)
    sep <- leap_csv_sep(lines[hdr_idx[1]])
    col_names <- trimws(leap_split_line(lines[hdr_idx[1]], sep))
    time_candidates <- c("Timestamp", "timestamp", "time", "datetime")
    time_col <- intersect(time_candidates, col_names)
    has_timestamp_column <- length(time_col) > 0L
    if (has_timestamp_column)
        time_col <- time_col[1]
    else time_col <- NA_character_
    x_col <- leap_pick_name(col_names, c("Accelerometer X", "Accelerometer.X", "X", "x", "acc_x", "accx"))
    y_col <- leap_pick_name(col_names, c("Accelerometer Y", "Accelerometer.Y", "Y", "y", "acc_y", "accy"))
    z_col <- leap_pick_name(col_names, c("Accelerometer Z", "Accelerometer.Z", "Z", "z", "acc_z", "accz"))
    first_data_line <- lines[hdr_idx[1] + 1L] %m_parser_or% NA_character_
    first_time <- as.POSIXct(NA, tz = tz_parsed)
    if (has_timestamp_column && !is.na(first_data_line) && nzchar(first_data_line)) {
        first_fields <- leap_split_line(first_data_line, sep)
        first_time <- leap_parse_timestamp(first_fields[match(time_col, col_names)] %m_parser_or% NA_character_,
            tz_parsed)  # first timestamp
    }
    if (is.na(first_time)) {
        start_date <- leap_preamble_value(pre, "^Start Date[[:space:]]+")
        start_time <- leap_preamble_value(pre, "^Start Time[[:space:]]+")
        if (!is.na(start_date) && !is.na(start_time))
            first_time <- leap_parse_timestamp(paste(start_date, start_time), tz_parsed)
    }
    regular_time <- is.finite(hz) && hz > 0 && !is.na(first_time)
    if (!has_timestamp_column && !regular_time) {
        stop("LEAP CSV parse failed: a CSV without Timestamp requires Start Date, Start Time, and a positive nominal sample rate in the ActiLife preamble.")
    }
    select_cols <- if (regular_time)
        c(x_col, y_col, z_col)
    else c(time_col, x_col, y_col, z_col)
    if (isTRUE(use_fast) && requireNamespace("data.table", quietly = TRUE)) {
        d <- data.table::fread(input = path, skip = hdr_idx[1] - 1L, sep = sep, header = TRUE, select = select_cols,
            data.table = FALSE, showProgress = FALSE)
        reader_name <- "data.table::fread"
    }
    else {
        d <- if (sep == "\t") {
            utils::read.table(path, header = TRUE, sep = "\t", quote = "", comment.char = "", stringsAsFactors = FALSE,
                check.names = FALSE, skip = hdr_idx[1] - 1)
        }
        else {
            utils::read.csv(path, skip = hdr_idx[1] - 1, stringsAsFactors = FALSE, check.names = FALSE)
        }
        reader_name <- if (sep == "\t")
            "utils::read.table"
        else "utils::read.csv"
    }
    ax <- d[[x_col]]
    ay <- d[[y_col]]
    az <- d[[z_col]]
    n <- length(ax)
    if (!n)
        stop("LEAP CSV parse failed: no acceleration samples were read.")
    if (regular_time && has_timestamp_column) {  # Verify generated timestamp bounds.
        last_data_line <- leap_last_nonempty_line(path)
        if (!is.na(last_data_line) && nzchar(last_data_line)) {
            last_fields <- leap_split_line(last_data_line, sep)
            last_time <- leap_parse_timestamp(last_fields[match(time_col, col_names)] %m_parser_or% NA_character_,
                tz_parsed)
            expected_last <- as.numeric(first_time) + (n - 1)/hz
            tolerance_s <- max(1/hz, 0.001)
            if (!is.na(last_time) && abs(as.numeric(last_time) - expected_last) > tolerance_s) {
                regular_time <- FALSE
                if (!(time_col %in% names(d))) {
                  d <- data.table::fread(input = path, skip = hdr_idx[1] - 1L, sep = sep, header = TRUE,
                    select = c(time_col, x_col, y_col, z_col), data.table = FALSE, showProgress = FALSE)
                  ax <- d[[x_col]]
                  ay <- d[[y_col]]
                  az <- d[[z_col]]
                  n <- length(ax)
                }
            }
        }
    }
    timestamp_grid <- if (regular_time) {
        if (has_timestamp_column)
            "generated_from_first_timestamp_and_sample_rate"
        else "generated_from_preamble_start_and_sample_rate"
    }
    else {
        "parsed_per_row"
    }
    if (!has_timestamp_column) {
        meta$file$warnings <- c(meta$file$warnings, "LEAP RAW CSV has no Timestamp column; timestamps were generated from ActiLife Start Date, Start Time, and nominal sample rate.")
    }
    if (regular_time) {  # synthesize regular timestamp grid
        time <- as.POSIXct(as.numeric(first_time) + (seq_len(n) - 1)/hz, origin = "1970-01-01", tz = tz_parsed)
    }
    else {  # fallback to row-wise timestamp parse
        time <- leap_parse_timestamp(d[[time_col]], tz_parsed)
        if (all(is.na(time)))
            stop("LEAP CSV parse failed: could not parse timestamps with %d/%m/%Y %H:%M:%OS.")
    }
    res <- apply_time_policy(time, meta, tz_declared = NA_character_, tz_parsed = tz_parsed, tz_source = "unknown",
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- if (regular_time)
        hz
    else derive_fs(time)
    meta$processing$decode_notes <- paste0("LEAP RAW CSV export; sep=", if (sep == "\t")
        "tab"
    else "comma", "; reader=", reader_name, "; timestamp_grid=", timestamp_grid)
    meta$processing$leap_csv_parser <- list(name = MJT_LEAP_CSV_PARSER_NAME, version = MJT_DEVICE_PARSER_VERSION,
        upstream_reference = "ActiGraph LEAP ActiLife RAW CSV export", implementation_change = paste("Replaced full-file readLines and delimiter retry with bounded header inspection.",
            "Reads only acceleration columns with data.table::fread when available and generates the regular timestamp grid from export metadata."))
    meta <- set_calibration_provenance(meta, status = "export_scaled_no_metronautica_calibration", scale_applied = TRUE,
        calibration_applied = FALSE, scale_source = "ActiLife RAW CSV exported acceleration columns",
        calibration_source = NA_character_, applied_by = "ActiLife export / source device", details = list(actilife_export_version = meta$processing$actilife_export_version %m_parser_or%
            NA_character_, timestamp_grid = timestamp_grid, timestamp_column_present = has_timestamp_column,
            sample_rate_hz = if (is.finite(hz)) hz else NA_real_), notes = "Metronautica reads the LEAP RAW CSV acceleration values as already exported in g. It does not apply additional scale or calibration coefficients.",
        caveats = c("Any calibration embedded in the CSV values is inherited from ActiLife/device export and is not independently reconstructed by this parser."))
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# HBK reference CSV decoding ----
detect_hbk_csv <- function(path, n = 80) {
    stopifnot(file.exists(path))
    x <- tryCatch(readLines(path, n = n, warn = FALSE), error = function(e) character(0))
    if (!length(x))
        return(FALSE)
    any(trimws(x) == "FILE_INFO") && any(trimws(x) == "CHANNEL_INFO") && any(trimws(x) == "DATA_START")
}

hbk_dtf_to_rfmt <- function(dtf_line) {
    if (is.na(dtf_line) || !nzchar(dtf_line))
        return(NA_character_)
    s <- trimws(sub("^DateTimeFormat\\b", "", dtf_line))
    s <- trimws(sub("^[[:space:],\\t]*", "", s))
    if (!nzchar(s))
        return(NA_character_)
    s <- gsub("yyyy", "%Y", s, fixed = TRUE)
    s <- gsub("yy", "%y", s, fixed = TRUE)
    s <- gsub("MM", "%m", s, fixed = TRUE)
    s <- gsub("dd", "%d", s, fixed = TRUE)
    s <- gsub("HH", "%H", s, fixed = TRUE)
    s <- gsub("hh", "%H", s, fixed = TRUE)
    s <- gsub("h", "%H", s, fixed = TRUE)
    s <- gsub("mm", "%M", s, fixed = TRUE)
    s <- gsub("ss", "%S", s, fixed = TRUE)
    s <- gsub("nnnnnnnnn", "%OS", s, fixed = TRUE)
    s <- gsub("nnn", "%OS", s, fixed = TRUE)
    s
}

hbk_time_to_seconds <- function(x) {
    x <- trimws(x)
    parts <- strsplit(x, ":", fixed = TRUE)
    vapply(parts, function(p) {
        p <- trimws(p)
        if (length(p) == 2L)
            return(as.numeric(p[1]) * 60 + as.numeric(p[2]))
        if (length(p) == 3L)
            return(as.numeric(p[1]) * 3600 + as.numeric(p[2]) * 60 + as.numeric(p[3]))
        as.numeric(p[1])
    }, numeric(1))
}

hbk_parse_time <- function(x, tz = "UTC", rfmt = NA_character_) {
    if (inherits(x, "POSIXct")) {
        attr(x, "tzone") <- tz
        return(x)
    }
    if (is.numeric(x)) {
        ok <- is.finite(x)
        if (any(ok) && median(x[ok], na.rm = TRUE) > 20000) {
            t <- as.POSIXct((x - 25569) * 86400, origin = "1970-01-01", tz = tz)
            attr(t, "tzone") <- tz
            return(t)
        }
        t <- as.POSIXct(x, origin = "1970-01-01", tz = tz)
        attr(t, "tzone") <- tz
        return(t)
    }
    x <- trimws(as.character(x))
    if (is.character(rfmt) && nzchar(rfmt)) {
        t <- as.POSIXct(x, format = rfmt, tz = tz)
        if (!all(is.na(t))) {
            attr(t, "tzone") <- tz
            return(t)
        }
    }
    fmt <- c("%m/%d/%y %H:%M:%OS", "%m/%d/%Y %H:%M:%OS", "%d/%m/%Y %H:%M:%OS", "%Y-%m-%d %H:%M:%OS")
    for (f in fmt) {
        t <- as.POSIXct(x, format = f, tz = tz)
        if (!all(is.na(t))) {
            attr(t, "tzone") <- tz
            return(t)
        }
    }
    num <- suppressWarnings(as.numeric(x))
    if (!all(is.na(num)) && median(num, na.rm = TRUE) > 20000) {
        t <- as.POSIXct((num - 25569) * 86400, origin = "1970-01-01", tz = tz)
        attr(t, "tzone") <- tz
        return(t)
    }
    sec <- hbk_time_to_seconds(x)
    t0 <- as.POSIXct("1970-01-01 00:00:00", tz = tz)
    t <- t0 + sec
    attr(t, "tzone") <- tz
    t
}

hbk_scan_header <- function(path) {
    con <- file(path, open = "r", encoding = "UTF-8")
    on.exit(close(con), add = TRUE)
    pre <- character()
    line_no <- 0L  # counter
    repeat {
        line <- readLines(con, n = 1L, warn = FALSE)
        if (!length(line))
            break
        line_no <- line_no + 1L
        if (identical(trimws(line), "DATA_START")) {
            hdr <- readLines(con, n = 1L, warn = FALSE)
            if (!length(hdr))
                stop("HBK CSV parse failed: DATA_START was found but no table header followed.")
            return(list(pre = pre, header_line = hdr[[1]], skip = line_no))
        }
        pre <- c(pre, line)
    }
    stop("HBK CSV parse failed: could not find 'DATA_START'.")
}

# HBK G-Link CSV parser ----
parse_hbk_glink_csv <- function(path, tz_parsed = "UTC", time_shift_s = 0, sensor_vendor = NA_character_,
    sensor_model = NA_character_, full_scale_range_g = NA_real_, return = c("data", "bundle"), hash_sha256 = NULL) {
    return <- match.arg(return)
    stopifnot(file.exists(path))
    meta <- meta_min_template(path, "hbk_glink_csv", parser = "HBK_export", parser_version = NA_character_,
        hash_sha256 = hash_sha256)
    meta$acquisition$device_vendor <- "HBK"
    meta$acquisition$device_model <- "G-Link-200"
    meta$acquisition$sensor_vendor <- sensor_vendor
    meta$acquisition$sensor_model <- sensor_model
    if (is.finite(full_scale_range_g) && full_scale_range_g > 0)
        meta$acquisition$full_scale_range_g <- as.numeric(full_scale_range_g)
    scanned <- hbk_scan_header(path)
    hdr_line <- scanned$header_line
    sep <- if (grepl("\t", hdr_line, fixed = TRUE))
        "\t"
    else ","
    pre <- scanned$pre
    tz_line <- pre[grepl("^TimeZone\\b", pre)][1]
    dtf_line <- pre[grepl("^DateTimeFormat\\b", pre)][1]
    tz_decl <- if (!is.na(tz_line))
        trimws(sub("^TimeZone\\b", "", tz_line))
    else NA_character_
    tz_decl <- trimws(sub("^[[:space:],\\t]*", "", tz_decl))
    tz_use <- if (!is.na(tz_decl) && nzchar(tz_decl))
        tz_decl
    else tz_parsed
    rfmt <- hbk_dtf_to_rfmt(dtf_line)
    if (requireNamespace("data.table", quietly = TRUE)) {
        d <- data.table::fread(path, skip = scanned$skip, header = TRUE, sep = sep, quote = "", select = 1:4,
            showProgress = FALSE, data.table = FALSE, check.names = FALSE)
        reader_name <- "data.table::fread"
    }
    else {
        d <- utils::read.table(path, skip = scanned$skip, header = TRUE, sep = sep, quote = "", comment.char = "",
            stringsAsFactors = FALSE, check.names = FALSE, fill = TRUE)[, 1:4, drop = FALSE]
        reader_name <- "utils::read.table"
    }
    if (ncol(d) < 4)
        stop("HBK CSV parse failed: expected Time + >=3 channels.")
    time_raw <- pick_col(d, c("Time", "time", "Timestamp", "timestamp", "DateTime", "Datetime", "dateTime"))
    time <- hbk_parse_time(time_raw, tz = tz_use, rfmt = rfmt)
    if (all(is.na(time)))
        stop("HBK CSV parse failed: could not parse Time column.")
    ch_names <- setdiff(names(d), names(d)[1])
    ax <- d[[ch_names[1]]]
    ay <- d[[ch_names[2]]]
    az <- d[[ch_names[3]]]
    meta$processing$decode_notes <- paste0("export=HBK_GLink_csv; sep=", if (sep == "\t")
        "tab"
    else "comma", if (!is.na(tz_line))
        paste0("; ", trimws(tz_line))
    else "", if (!is.na(dtf_line))
        paste0("; ", trimws(dtf_line))
    else "")
    meta$processing$hbk_glink_parser <- list(name = "HBK_export", version = NA_character_, upstream_reference = "HBK G-Link-200 CSV export with FILE_INFO / CHANNEL_INFO / DATA_START sections",
        implementation_change = paste0("Metronautica scans the metadata header, reads only Time plus the first three exported channels with ",
            reader_name, ", and wraps them into the app raw signal schema."))
    meta <- set_calibration_provenance(meta, status = "export_units_assumed", scale_applied = FALSE,
        calibration_applied = FALSE, scale_source = "HBK exported channel values", calibration_source = NA_character_,
        applied_by = "HBK export / source file", details = list(channel_names = as.list(ch_names[1:3])),
        notes = "Metronautica does not currently parse HBK channel unit calibration coefficients; the first three exported channels are treated as raw acceleration axes.",
        caveats = c("Confirm exported HBK channel units before comparing against calibrated g-scale device outputs."))
    tz_src <- if (!is.na(tz_decl) && nzchar(tz_decl))
        "declared"
    else "user"
    res <- apply_time_policy(time, meta, tz_declared = tz_decl, tz_parsed = tz_use, tz_source = tz_src,
        time_shift_s = time_shift_s)
    time <- res$time
    meta <- res$meta
    meta$acquisition$fs_nominal_hz <- suppressWarnings(as.numeric(sub(".*\\b([0-9]+(?:\\.[0-9]+)?)\\s*Hz\\b.*",
        "\\1", pre[grepl("\\bHz\\b", pre)][1] %m_parser_or% "", perl = TRUE)))
    if (!is.finite(meta$acquisition$fs_nominal_hz))
        meta$acquisition$fs_nominal_hz <- NA_real_
    meta$acquisition$start_utc <- min(time, na.rm = TRUE)
    meta$acquisition$end_utc <- max(time, na.rm = TRUE)
    meta$acquisition$fs_derived_hz <- derive_fs(time)
    x <- as_accel_tbl(time, as.numeric(ax), as.numeric(ay), as.numeric(az), meta)
    if (return == "data")
        return(x)
    list(data = x, meta = accel_meta(x))
}

# Auto-detection and dispatcher
detect_device_bin <- function(path) {
    h <- tryCatch(GENEAread::header.info(binfile = path, more = TRUE), error = function(e) NULL)
    if (!is.null(h) && nrow(h))
        return("geneactiv_bin")
    file_size <- as.numeric(file.info(path)$size)  # bytes
    if (is.finite(file_size) && file_size > 0 && file_size%%12 == 0)
        return("sens_bin")
    "unknown"
}

# Run default post-decode QC.
# Store diagnostics in processing metadata.
# Standalone parsing requires m_qc.R.

# Detect format and dispatch ----
parse_raw_auto <- function(path, return = c("data", "bundle"), verbose = FALSE, progress = FALSE, time_shift_s = 0,
    tz_parsed = "UTC", hash_sha256 = NULL, qc = TRUE, ...) {
    return <- match.arg(return)
    if (!is.logical(qc) || length(qc) != 1L || is.na(qc)) {
        stop("qc must be TRUE or FALSE.", call. = FALSE)
    }
    qc_attach <- NULL
    if (qc) {
        qc_attach <- get0("attach_qc", mode = "function", inherits = TRUE)
        if (is.null(qc_attach)) {
            stop("qc = TRUE requires the QC functions; source m_qc.R before parsing.", call. = FALSE)
        }
    }
    stopifnot(file.exists(path))
    ext <- tolower(tools::file_ext(path))
    t0 <- Sys.time()
    pb <- mk_pb(enabled = progress, steps = 4L)
    if (isTRUE(verbose))
        message("[parse_raw_auto] start -> ", basename(path))
    pb_step(pb, 1L)
    if (isTRUE(verbose))
        message("[parse_raw_auto] detect ext: ", ext)
    pb_step(pb, 2L)

    out <- NULL

    if (ext == "bin") {
        dev <- detect_device_bin(path)
        if (isTRUE(verbose))
            message("[parse_raw_auto] bin subtype: ", dev)
        if (dev == "geneactiv_bin")
            out <- parse_genea_bin(path, return = return, time_shift_s = time_shift_s, hash_sha256 = hash_sha256,
                ...)
        if (dev == "sens_bin")
            out <- parse_sens_bin(path, return = return, time_shift_s = time_shift_s, hash_sha256 = hash_sha256,
                ...)
        if (is.null(out))
            stop("Unknown .bin format.")
    }

    if (ext == "cwa")
        out <- parse_axivity_cwa(path, return = return, desiredtz = tz_parsed, time_shift_s = time_shift_s,
            hash_sha256 = hash_sha256, ...)
    if (ext == "gt3x")
        out <- parse_act_gt3x(path, return = return, time_shift_s = time_shift_s, hash_sha256 = hash_sha256,
            ...)

    if (ext == "agsd")
        out <- parse_act_leap_agsd(path, return = return, tz_parsed = tz_parsed, time_shift_s = time_shift_s,
            hash_sha256 = hash_sha256, ...)

    if (ext == "csv") {
        if (detect_hbk_csv(path))
            out <- parse_hbk_glink_csv(path, return = return, tz_parsed = tz_parsed, time_shift_s = time_shift_s,
                hash_sha256 = hash_sha256, ...)
        if (is.null(out) && detect_axivity_csv(path))
            out <- parse_axivity_csv(path, return = return, tz_parsed = tz_parsed, time_shift_s = time_shift_s,
                hash_sha256 = hash_sha256, ...)
        if (is.null(out) && detect_act_leap_csv(path))
            out <- parse_act_leap_csv(path, return = return, tz_parsed = tz_parsed, time_shift_s = time_shift_s,
                hash_sha256 = hash_sha256, ...)
        if (is.null(out))
            stop("CSV format not recognised.")
    }

    if (is.null(out))
        stop("Unsupported extension: ", ext)
    if (qc) {
        if (isTRUE(verbose))
            message("[parse_raw_auto] run signal diagnostics")
        out <- qc_attach(out)
    }
    pb_step(pb, 3L)
    pb_step(pb, 4L)
    pb_close(pb)

    if (isTRUE(verbose)) {
        dt <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)
        message("[parse_raw_auto] done (", dt, " s)")
    }

    out
}

# Validate dependency interface before reading.
# Require the validated decoder version.

# Validate bounded decoder interface ----
check_gt3x_bounded_interface <- function(version, decoder) {
    expected_names <- c("filename", "max_samples", "scale_factor", "sample_rate", "start_time", "batch_begin",
        "batch_end", "verbose", "debug", "impute_zeroes")
    expected_defaults <- alist(batch_begin = 0L, batch_end = 0L, verbose = FALSE, debug = FALSE, impute_zeroes = FALSE)
    if (!identical(as.character(version), "1.2.0") || !is.function(decoder) || !identical(names(formals(decoder)),
        expected_names) || !identical(formals(decoder)[names(expected_defaults)], expected_defaults)) {
        stop("Bounded GT3X decoding requires the validated read.gt3x 1.2.0 interface. ", "Revalidate this helper before using another decoder version or interface; ",
            "the public full-file parser remains available separately.", call. = FALSE)
    }
    decoder
}

# Decode bounded GT3X intervals.

# Bounded native-precision decoding ----
parse_gt3x_through <- function(path, through, full_scale_range_g = 16) {
    if (!requireNamespace("read.gt3x", quietly = TRUE))
        stop("Bounded GT3X decoding requires read.gt3x 1.2.0", call. = FALSE)
    decoder_namespace <- asNamespace("read.gt3x")
    decoder <- get0("parseGT3X", envir = decoder_namespace, inherits = FALSE)
    decoder <- check_gt3x_bounded_interface(utils::packageVersion("read.gt3x"), decoder)
    info <- read.gt3x::parse_gt3x_info(path, tz = "GMT")
    fs <- as.numeric(info[["Sample Rate"]])
    start <- info[["Start Date"]]
    n <- ceiling((as.numeric(through) - as.numeric(start) + 60) * fs)
    stopifnot(is.finite(n), n > 0, n < .Machine$integer.max)
    tmp <- tempfile("qc_secondary_")
    dir.create(tmp)
    on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
    utils::unzip(path, files = c("info.txt", "log.bin"), exdir = tmp, junkpaths = TRUE)
    a <- decoder(file.path(tmp, "log.bin"), max_samples = as.integer(n), scale_factor = as.numeric(info[["Acceleration Scale"]]),
        sample_rate = fs, start_time = as.numeric(start), verbose = FALSE, impute_zeroes = FALSE)
    stopifnot(length(attr(a, "time_index")) == nrow(a))
    attr(a, "start_time") <- start
    attr(a, "add_light") <- FALSE
    class(a) <- c("activity", class(a))
    d <- as.data.frame(a)
    attr(d$time, "tzone") <- "UTC"  # GMT and UTC preserve instants.
    meta <- meta_min_template(path, "actigraph_gt3x_bounded", "read.gt3x::parseGT3X", as.character(packageVersion("read.gt3x")))
    meta$acquisition$device_id <- info[["Serial Number"]]
    meta$acquisition$full_scale_range_g <- full_scale_range_g
    meta$acquisition$fs_nominal_hz <- fs
    meta$processing$decode_notes <- paste("Bounded GT3X decode through", through, "UTC plus 60 s; upstream time_index retained; no imputation.")
    as_accel_tbl(d$time, d$X, d$Y, d$Z, meta)
}
