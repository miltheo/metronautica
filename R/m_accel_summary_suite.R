# ======================================================================
# Epoch-level acceleration features
# Input: common-format time, ax_g, ay_g and az_g columns, or a parser bundle.
# Functions calculate requested features and return results with processing settings.
# Cohort analysis, trial orchestration and master-sheet management belong to callers.
# ======================================================================

# ======================================================================
# 0. Packages
# ======================================================================

load_summary_packages <- function() {
    packages <- c("dplyr", "tibble", "ggplot2", "signal", "utils")

    for (pkg in packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
            stop("Install required package before processing: ", pkg, call. = FALSE)
        }
    }

    invisible(TRUE)
}

# Namespace checks run when calculations are requested, never at package load.

# Keep standalone sourcing compatible without attaching dplyr to the search path.
`%>%` <- dplyr::`%>%`


# ======================================================================
# 1. General utilities
# ======================================================================

`%||%` <- function(a, b) {
    if (!is.null(a) && length(a) > 0 && !all(is.na(a))) a else b
}

first_present <- function(...) {
    xs <- list(...)

    for (x in xs) {
        if (is.null(x) || length(x) == 0) next
        if (length(x) > 1) x <- x[1]

        if (is.character(x)) {
            if (!is.na(x) && nzchar(trimws(x))) return(trimws(x))
        } else {
            if (!is.na(x)) return(x)
        }
    }

    NA
}

vm_calc <- function(ax, ay, az) {
    sqrt(ax^2 + ay^2 + az^2)
}

# ======================================================================
# 2. Metric metadata
# ======================================================================

metric_order <- function() {
    c(
        "VM", "ENMO", "MAD",
        "ODBA", "VEDBA", "PDBA",
        "SVMGS", "SVMGSEC", "SVMGMEAN",
        "SVMBP", "SVMBP_02_15", "SVMBP_069_10",
        "ROCAM", "AI", "ZANGLE", "ZANGLE_CHANGE",
        "MIMS"
    )
}

# ======================================================================
# 3. Input handling
# ======================================================================

accel_unpack_input <- function(accel_input) {
    if (inherits(accel_input, "tbl_df") || inherits(accel_input, "data.frame")) {
        tbl <- accel_input
        meta <- attr(tbl, "meta")
        source_type <- "accel_tbl"

    } else if (is.list(accel_input)) {
        if ("full" %in% names(accel_input)) {
            tbl <- accel_input$full
            meta <- attr(tbl, "meta") %||% accel_input$meta
            source_type <- "clip_bundle"
        } else if ("data" %in% names(accel_input)) {
            tbl <- accel_input$data
            meta <- attr(tbl, "meta") %||% accel_input$meta
            source_type <- "parse_bundle"
        } else {
            stop("Input list must contain either $full or $data.")
        }

    } else {
        stop("accel_input must be an accel_tbl/data.frame or supported bundle.")
    }

    req <- c("time", "ax_g", "ay_g", "az_g")
    miss <- setdiff(req, names(tbl))

    if (length(miss)) {
        stop("Missing required columns: ", paste(miss, collapse = ", "))
    }

    tbl <- tibble::as_tibble(tbl)[, req]
    tbl <- dplyr::arrange(tbl, time)

    if (!inherits(tbl$time, "POSIXct")) {
        stop("Column 'time' must be POSIXct.")
    }

    list(tbl = tbl, meta = meta, source_type = source_type)
}


accel_get_fs <- function(tbl, meta = NULL, fs_hz = NULL, quiet = FALSE) {
    if (!is.null(fs_hz) && is.finite(fs_hz) && fs_hz > 0) {
        return(as.numeric(fs_hz))
    }

    fs_meta <- tryCatch(
        meta$acquisition$fs_derived_hz %||% meta$acquisition$fs_nominal_hz,
        error = function(e) NULL
    )

    if (!is.null(fs_meta) && is.finite(fs_meta) && fs_meta > 0) {
        return(as.numeric(fs_meta))
    }

    dt <- as.numeric(diff(tbl$time), units = "secs")
    dt <- dt[is.finite(dt) & dt > 0]

    if (!length(dt)) {
        stop("Could not determine sampling frequency.")
    }

    fs <- 1 / stats::median(dt)

    if (!quiet) {
        message(sprintf("[fs] Estimated from timestamps: %.5f Hz", fs))
    }

    as.numeric(fs)
}


accel_get_dynamic_range <- function(meta = NULL, dynamic_range_g = NULL, required = TRUE) {
    valid <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x) && x > 0
    if (!is.null(dynamic_range_g)) {
        if (!valid(dynamic_range_g)) stop("dynamic_range_g must be one finite positive peak-to-peak span in g (16 means +/-8 g).")
        return(as.numeric(dynamic_range_g))
    }
    dr <- tryCatch(meta$acquisition$full_scale_range_g, error = function(e) NULL)
    if (valid(dr)) return(as.numeric(dr))
    if (required) stop("MIMS requires dynamic_range_g or valid acquisition$full_scale_range_g metadata; no measurement range is assumed.")
    NA_real_
}


accel_resample_linear <- function(tbl, target_fs) {
    if (!is.finite(target_fs) || target_fs <= 0) {
        stop("target_fs must be > 0.")
    }

    t0 <- tbl$time[1]
    sec <- as.numeric(tbl$time - t0, units = "secs")
    sec_new <- seq(min(sec), max(sec), by = 1 / target_fs)

    tibble::tibble(
        time = t0 + sec_new,
        ax_g = stats::approx(sec, tbl$ax_g, xout = sec_new, method = "linear", rule = 2)$y,
        ay_g = stats::approx(sec, tbl$ay_g, xout = sec_new, method = "linear", rule = 2)$y,
        az_g = stats::approx(sec, tbl$az_g, xout = sec_new, method = "linear", rule = 2)$y
    )
}


accel_regularise_time <- function(tbl, fs_hz, anchor = c("floor_sec", "round_sec")) {
    anchor <- match.arg(anchor)
    fs_use <- round(fs_hz)
    t0_num <- as.numeric(tbl$time[1])
    t0_base <- if (anchor == "floor_sec") floor(t0_num) else round(t0_num)

    tbl$time <- as.POSIXct(
        t0_base + seq(0, by = 1 / fs_use, length.out = nrow(tbl)),
        origin = "1970-01-01",
        tz = "UTC"
    )

    tbl
}


accel_make_epoch_index <- function(tbl, epoch_s, anchor = c("center", "start", "end")) {
    anchor <- match.arg(anchor)

    if (!is.finite(epoch_s) || epoch_s <= 0) {
        stop("epoch_s must be > 0.")
    }

    t0 <- tbl$time[1]
    sec <- as.numeric(tbl$time - t0, units = "secs")
    epoch_id <- floor(sec / epoch_s) + 1L

    epoch_time <- tibble::tibble(time = tbl$time, epoch_id = epoch_id) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            time = dplyr::case_when(
                anchor == "start" ~ dplyr::first(time),
                anchor == "end" ~ dplyr::last(time),
                TRUE ~ time[ceiling(dplyr::n() / 2)]
            ),
            .groups = "drop"
        )

    list(epoch_id = epoch_id, epoch_time = epoch_time)
}


accel_join_epoch_time <- function(out, epoch_time) {
    out %>%
        dplyr::left_join(epoch_time, by = "epoch_id") %>%
        dplyr::select(time, epoch_id, dplyr::everything())
}


# ======================================================================
# 4. Filter helpers
# ======================================================================

accel_lowpass_antialias <- function(tbl, fs_hz, cutoff_hz, order = 4) {
    if (!requireNamespace("signal", quietly = TRUE)) {
        stop("Package 'signal' is required.")
    }

    wn <- cutoff_hz / (fs_hz / 2)

    if (!is.finite(wn) || wn <= 0 || wn >= 1) {
        stop("cutoff_hz must be below Nyquist.")
    }

    bf <- signal::butter(order, wn, type = "low")

    tbl$ax_g <- as.numeric(signal::filtfilt(bf, tbl$ax_g))
    tbl$ay_g <- as.numeric(signal::filtfilt(bf, tbl$ay_g))
    tbl$az_g <- as.numeric(signal::filtfilt(bf, tbl$az_g))

    tbl
}


accel_lowpass_axes <- function(tbl, fs_hz, cutoff_hz, order = 4) {
    if (!requireNamespace("signal", quietly = TRUE)) {
        stop("Package 'signal' is required.")
    }

    wn <- cutoff_hz / (fs_hz / 2)

    if (!is.finite(wn) || wn <= 0 || wn >= 1) {
        stop("cutoff_hz must be below Nyquist.")
    }

    bf <- signal::butter(order, wn, type = "low")

    tibble::tibble(
        time = tbl$time,
        ax_g = as.numeric(signal::filtfilt(bf, tbl$ax_g)),
        ay_g = as.numeric(signal::filtfilt(bf, tbl$ay_g)),
        az_g = as.numeric(signal::filtfilt(bf, tbl$az_g))
    )
}


accel_highpass_axes <- function(tbl, fs_hz, cutoff_hz, order = 4) {
    if (!requireNamespace("signal", quietly = TRUE)) {
        stop("Package 'signal' is required.")
    }

    wn <- cutoff_hz / (fs_hz / 2)

    if (!is.finite(wn) || wn <= 0 || wn >= 1) {
        stop("cutoff_hz must be below Nyquist.")
    }

    bf <- signal::butter(order, wn, type = "high")

    tibble::tibble(
        time = tbl$time,
        ax_g = as.numeric(signal::filtfilt(bf, tbl$ax_g)),
        ay_g = as.numeric(signal::filtfilt(bf, tbl$ay_g)),
        az_g = as.numeric(signal::filtfilt(bf, tbl$az_g))
    )
}


accel_resolve_bandpass <- function(
        fs_hz,
        cutoffs_hz,
        nyquist_action = c("stop", "clip"),
        quiet = FALSE
) {
    nyquist_action <- match.arg(nyquist_action)

    low <- as.numeric(cutoffs_hz[1])
    high <- as.numeric(cutoffs_hz[2])
    nyq <- fs_hz / 2

    if (!is.finite(low) || !is.finite(high) || low <= 0 || high <= 0) {
        stop("Band-pass cutoffs must be positive finite values.")
    }

    if (high >= nyq) {
        if (nyquist_action == "stop") {
            stop(sprintf("High cutoff %.3f Hz must be below Nyquist %.3f Hz.", high, nyq))
        }

        high_old <- high
        high <- nyq * 0.99

        if (!quiet) {
            message(sprintf("[bandpass] high cutoff clipped from %.3f Hz to %.3f Hz", high_old, high))
        }
    }

    if (low >= high) {
        stop("Low cutoff must be below high cutoff.")
    }

    c(low, high)
}


accel_bandpass_axes <- function(
        tbl,
        fs_hz,
        cutoffs_hz = c(0.2, 15),
        order = 4,
        nyquist_action = c("stop", "clip"),
        quiet = FALSE
) {
    if (!requireNamespace("signal", quietly = TRUE)) {
        stop("Package 'signal' is required.")
    }

    nyquist_action <- match.arg(nyquist_action)
    bp <- accel_resolve_bandpass(fs_hz, cutoffs_hz, nyquist_action, quiet)
    wn <- bp / (fs_hz / 2)
    bf <- signal::butter(order, wn, type = "pass")

    out <- tibble::tibble(
        time = tbl$time,
        ax_g = as.numeric(signal::filtfilt(bf, tbl$ax_g)),
        ay_g = as.numeric(signal::filtfilt(bf, tbl$ay_g)),
        az_g = as.numeric(signal::filtfilt(bf, tbl$az_g))
    )
    attr(out, "settings") <- list(requested_cutoffs_hz = cutoffs_hz,
        applied_cutoffs_hz = bp, fs_hz = fs_hz, order = order,
        nyquist_action = nyquist_action, implementation = "signal::butter/filtfilt")
    out
}


accel_running_mean_centered <- function(x, window_n) {
    n <- length(x)
    if (!n) return(numeric())

    k <- max(1L, as.integer(round(window_n)))
    left <- floor((k - 1L) / 2L)
    right <- k - 1L - left
    idx <- seq_len(n)
    start <- pmax(1L, idx - left)
    end <- pmin(n, idx + right)

    ok <- is.finite(x)
    vals <- ifelse(ok, x, 0)
    cs <- c(0, cumsum(vals))
    cc <- c(0L, cumsum(ok))
    sums <- cs[end + 1L] - cs[start]
    counts <- cc[end + 1L] - cc[start]
    out <- sums / counts
    out[counts == 0L] <- NA_real_
    out
}


accel_resolve_odba_window_s <- function(
        rule = c("fixed_3s", "custom_window_s", "stroke_period_1x", "stroke_period_2x", "sensitivity_windows"),
        running_mean_window_s = 3,
        stroke_period_s = NA_real_
) {
    rule <- match.arg(rule)
    win <- suppressWarnings(as.numeric(running_mean_window_s))
    stroke <- suppressWarnings(as.numeric(stroke_period_s))

    if (rule == "fixed_3s") {
        return(3)
    }
    if (rule == "custom_window_s") {
        if (!is.finite(win) || win <= 0) stop("running_mean_window_s must be positive for custom ODBA windows.")
        return(win)
    }
    if (rule == "stroke_period_1x") {
        if (!is.finite(stroke) || stroke <= 0) stop("stroke_period_s must be positive for stroke-period ODBA windows.")
        return(max(3, stroke))
    }
    if (rule == "stroke_period_2x") {
        if (!is.finite(stroke) || stroke <= 0) stop("stroke_period_s must be positive for stroke-period ODBA windows.")
        return(max(3, 2 * stroke))
    }

    if (!is.finite(win) || win <= 0) return(3)
    win
}


accel_dynamic_components <- function(
        tbl,
        fs_hz,
        static_dynamic_method = c("centered_running_mean", "low_pass_static_filter", "high_pass_dynamic_filter"),
        running_mean_window_s = 3,
        lowpass_cutoff_hz = 0.2,
        highpass_cutoff_hz = 0.2,
        filter_order = 4
) {
    static_dynamic_method <- match.arg(static_dynamic_method)

    if (static_dynamic_method == "centered_running_mean") {
        window_n <- max(1L, round(fs_hz * running_mean_window_s))
        sx <- accel_running_mean_centered(tbl$ax_g, window_n)
        sy <- accel_running_mean_centered(tbl$ay_g, window_n)
        sz <- accel_running_mean_centered(tbl$az_g, window_n)
        return(tibble::tibble(
            time = tbl$time,
            dx_g = tbl$ax_g - sx,
            dy_g = tbl$ay_g - sy,
            dz_g = tbl$az_g - sz
        ))
    }

    if (static_dynamic_method == "low_pass_static_filter") {
        static_tbl <- accel_lowpass_axes(tbl, fs_hz, cutoff_hz = lowpass_cutoff_hz, order = filter_order)
        return(tibble::tibble(
            time = tbl$time,
            dx_g = tbl$ax_g - static_tbl$ax_g,
            dy_g = tbl$ay_g - static_tbl$ay_g,
            dz_g = tbl$az_g - static_tbl$az_g
        ))
    }

    dynamic_tbl <- accel_highpass_axes(tbl, fs_hz, cutoff_hz = highpass_cutoff_hz, order = filter_order)
    tibble::tibble(
        time = dynamic_tbl$time,
        dx_g = dynamic_tbl$ax_g,
        dy_g = dynamic_tbl$ay_g,
        dz_g = dynamic_tbl$az_g
    )
}


# ======================================================================
# 5. Metric functions
# ======================================================================

accel_metric_vm <- function(
        tbl,
        epoch_s,
        anchor = "center",
        summary_fun = c("mean", "sd", "max", "p95"),
        out_unit = c("g", "mg")
) {
    tbl <- qc_input_data(tbl)
    summary_fun <- match.arg(summary_fun)
    out_unit <- match.arg(out_unit)

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)
    vm <- vm_calc(tbl$ax_g, tbl$ay_g, tbl$az_g)

    out <- tibble::tibble(epoch_id = ep$epoch_id, value = vm) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = dplyr::case_when(
                summary_fun == "mean" ~ mean(value, na.rm = TRUE),
                summary_fun == "sd" ~ stats::sd(value, na.rm = TRUE),
                summary_fun == "max" ~ max(value, na.rm = TRUE),
                TRUE ~ as.numeric(stats::quantile(value, 0.95, na.rm = TRUE))
            ),
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)

    if (out_unit == "mg") {
        out$value <- out$value * 1000
    }

    out
}


accel_metric_enmo <- function(tbl, epoch_s, anchor = "center", out_unit = c("mg", "g")) {
    tbl <- qc_input_data(tbl)
    out_unit <- match.arg(out_unit)

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)
    en <- pmax(vm_calc(tbl$ax_g, tbl$ay_g, tbl$az_g) - 1, 0)

    out <- tibble::tibble(epoch_id = ep$epoch_id, value = en) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
        accel_join_epoch_time(ep$epoch_time)

    if (out_unit == "mg") {
        out$value <- out$value * 1000
    }

    out
}


accel_metric_mad <- function(tbl, epoch_s, anchor = "center", out_unit = c("mg", "g")) {
    tbl <- qc_input_data(tbl)
    out_unit <- match.arg(out_unit)

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)

    tmp <- tibble::tibble(
        epoch_id = ep$epoch_id,
        vm = vm_calc(tbl$ax_g, tbl$ay_g, tbl$az_g)
    )

    out <- tmp %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = mean(abs(vm - mean(vm, na.rm = TRUE)), na.rm = TRUE),
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)

    if (out_unit == "mg") {
        out$value <- out$value * 1000
    }

    out
}


accel_metric_odba <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor = "center",
        output = c("ODBA", "VEDBA", "PDBA"),
        static_dynamic_method = c("centered_running_mean", "low_pass_static_filter", "high_pass_dynamic_filter"),
        stroke_window_rule = c("fixed_3s", "custom_window_s", "stroke_period_1x", "stroke_period_2x", "sensitivity_windows"),
        running_mean_window_s = 3,
        stroke_period_s = NA_real_,
        lowpass_cutoff_hz = 0.2,
        highpass_cutoff_hz = 0.2,
        filter_type = "butterworth",
        filter_order = 4,
        pdba_axes = c("x", "y"),
        out_unit = c("mg", "g"),
        edge_handling = "partial_centered_window",
        missing_data_policy = "mean_na_rm"
) {
    tbl <- qc_input_data(tbl)
    output <- match.arg(output)
    static_dynamic_method <- match.arg(static_dynamic_method)
    stroke_window_rule <- match.arg(stroke_window_rule)
    out_unit <- match.arg(out_unit)

    window_s <- accel_resolve_odba_window_s(
        rule = stroke_window_rule,
        running_mean_window_s = running_mean_window_s,
        stroke_period_s = stroke_period_s
    )

    dyn <- accel_dynamic_components(
        tbl = tbl,
        fs_hz = fs_hz,
        static_dynamic_method = static_dynamic_method,
        running_mean_window_s = window_s,
        lowpass_cutoff_hz = lowpass_cutoff_hz,
        highpass_cutoff_hz = highpass_cutoff_hz,
        filter_order = filter_order
    )

    pdba_axes <- unique(tolower(as.character(pdba_axes)))
    pdba_axes <- pdba_axes[pdba_axes %in% c("x", "y", "z")]
    if (!length(pdba_axes)) pdba_axes <- c("x", "y")

    abs_axes <- list(
        x = abs(dyn$dx_g),
        y = abs(dyn$dy_g),
        z = abs(dyn$dz_g)
    )

    value <- switch(
        output,
        ODBA = abs_axes$x + abs_axes$y + abs_axes$z,
        VEDBA = sqrt(dyn$dx_g^2 + dyn$dy_g^2 + dyn$dz_g^2),
        PDBA = Reduce(`+`, abs_axes[pdba_axes])
    )

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)

    out <- tibble::tibble(epoch_id = ep$epoch_id, value = value) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
        accel_join_epoch_time(ep$epoch_time)

    if (out_unit == "mg") {
        out$value <- out$value * 1000
    }

    attr(out, "odba_settings") <- list(
        metric = output,
        static_dynamic_method = static_dynamic_method,
        filter_type = filter_type,
        filter_order = filter_order,
        lowpass_cutoff_hz = lowpass_cutoff_hz,
        highpass_cutoff_hz = highpass_cutoff_hz,
        running_mean_window_s = window_s,
        requested_running_mean_window_s = running_mean_window_s,
        stroke_period_s = stroke_period_s,
        stroke_window_rule = stroke_window_rule,
        pdba_axes = pdba_axes,
        epoch_length_s = epoch_s,
        summary_statistic = "epoch mean",
        edge_handling = edge_handling,
        missing_data_policy = missing_data_policy,
        output_unit = out_unit
    )

    out
}


accel_odba_sensitivity_summary <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor,
        metrics,
        windows_s = c(1, 2, 3, 5, 10),
        static_dynamic_method = "centered_running_mean",
        stroke_period_s = NA_real_,
        lowpass_cutoff_hz = 0.2,
        highpass_cutoff_hz = 0.2,
        filter_type = "butterworth",
        filter_order = 4,
        pdba_axes = c("x", "y"),
        out_unit = "mg",
        edge_handling = "partial_centered_window",
        missing_data_policy = "mean_na_rm"
) {
    metrics <- intersect(toupper(metrics), c("ODBA", "VEDBA", "PDBA"))
    windows_s <- as.numeric(windows_s)
    windows_s <- windows_s[is.finite(windows_s) & windows_s > 0]
    if (!length(metrics) || !length(windows_s)) return(tibble::tibble())

    rows <- list()
    for (metric in metrics) {
        for (win in windows_s) {
            out <- accel_metric_odba(
                tbl = tbl,
                epoch_s = epoch_s,
                fs_hz = fs_hz,
                anchor = anchor,
                output = metric,
                static_dynamic_method = static_dynamic_method,
                stroke_window_rule = "custom_window_s",
                running_mean_window_s = win,
                stroke_period_s = stroke_period_s,
                lowpass_cutoff_hz = lowpass_cutoff_hz,
                highpass_cutoff_hz = highpass_cutoff_hz,
                filter_type = filter_type,
                filter_order = filter_order,
                pdba_axes = pdba_axes,
                out_unit = out_unit,
                edge_handling = edge_handling,
                missing_data_policy = missing_data_policy
            )
            vals <- out$value[is.finite(out$value)]
            rows[[length(rows) + 1L]] <- tibble::tibble(
                metric = metric,
                running_mean_window_s = win,
                n_epochs = length(vals),
                mean_value = if (length(vals)) mean(vals, na.rm = TRUE) else NA_real_,
                sd_value = if (length(vals) > 1) stats::sd(vals, na.rm = TRUE) else NA_real_
            )
        }
    }

    dplyr::bind_rows(rows)
}


accel_metric_svmg <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor = "center",
        output = c("g_seconds", "sample_sum_g", "mean_mg", "mean_g"),
        rectify = TRUE
) {
    tbl <- qc_input_data(tbl)
    output <- match.arg(output)

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)

    sv <- vm_calc(tbl$ax_g, tbl$ay_g, tbl$az_g) - 1
    if (isTRUE(rectify)) sv <- abs(sv)

    tibble::tibble(epoch_id = ep$epoch_id, value = sv) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = dplyr::case_when(
                output == "sample_sum_g" ~ sum(value, na.rm = TRUE),
                output == "g_seconds" ~ sum(value, na.rm = TRUE) / fs_hz,
                output == "mean_g" ~ mean(value, na.rm = TRUE),
                TRUE ~ mean(value, na.rm = TRUE) * 1000
            ),
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)
}


accel_metric_svmbp <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor = "center",
        cutoffs_hz = c(0.2, 15),
        order = 4,
        output = c("mean_mg", "mean_g", "sum_mg", "sum_g", "g_seconds"),
        nyquist_action = c("stop", "clip"),
        quiet = FALSE
) {
    tbl <- qc_input_data(tbl)
    output <- match.arg(output)
    nyquist_action <- match.arg(nyquist_action)

    bp_tbl <- accel_bandpass_axes(tbl, fs_hz, cutoffs_hz, order, nyquist_action, quiet)
    ep <- accel_make_epoch_index(bp_tbl, epoch_s, anchor)
    svmbp <- vm_calc(bp_tbl$ax_g, bp_tbl$ay_g, bp_tbl$az_g)

    out <- tibble::tibble(epoch_id = ep$epoch_id, value = svmbp) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = dplyr::case_when(
                output == "mean_g" ~ mean(value, na.rm = TRUE),
                output == "sum_mg" ~ sum(value, na.rm = TRUE) * 1000,
                output == "sum_g" ~ sum(value, na.rm = TRUE),
                output == "g_seconds" ~ sum(value, na.rm = TRUE) / fs_hz,
                TRUE ~ mean(value, na.rm = TRUE) * 1000
            ),
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)
    attr(out, "settings") <- c(attr(bp_tbl, "settings"), list(output = output,
        epoch_s = epoch_s, epoch_anchor = anchor))
    out
}


accel_metric_rocam <- function(tbl, epoch_s, fs_hz, anchor = "center", median_s = 1) {
    tbl <- qc_input_data(tbl)
    raw <- c(NA_real_, sqrt(diff(tbl$ax_g)^2 + diff(tbl$ay_g)^2 + diff(tbl$az_g)^2))

    k <- max(3L, as.integer(round(fs_hz * median_s)))
    if (k %% 2L == 0L) k <- k + 1L

    filt <- as.numeric(stats::runmed(raw, k = k, endrule = "median"))

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)

    tibble::tibble(epoch_id = ep$epoch_id, value = filt) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
        accel_join_epoch_time(ep$epoch_time)
}


accel_estimate_ai_noise <- function(
        tbl,
        fs_hz,
        ai_noise_var = NULL,
        ai_noise_mode = c("supplied", "window_start", "quiet_segments"),
        ai_noise_window_s = 30,
        ai_quiet_quantile = 0.1
) {
    ai_noise_mode <- match.arg(ai_noise_mode)

    valid <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x) && x >= 0
    if (!is.null(ai_noise_var)) {
        if (!valid(ai_noise_var)) stop("ai_noise_var must be one finite non-negative mean per-axis noise variance in g squared.")
        return(as.numeric(ai_noise_var))
    }
    if (ai_noise_mode == "supplied") stop("Activity Index requires ai_noise_var from a stationary recording, or an explicit ai_noise_mode estimation choice.")
    if (!is.numeric(fs_hz) || length(fs_hz) != 1L || !is.finite(fs_hz) || fs_hz <= 0) stop("fs_hz must be finite and positive for noise estimation.")
    if (!is.numeric(ai_noise_window_s) || length(ai_noise_window_s) != 1L || !is.finite(ai_noise_window_s) || ai_noise_window_s <= 0) stop("ai_noise_window_s must be finite and positive.")
    if (!is.numeric(ai_quiet_quantile) || length(ai_quiet_quantile) != 1L || !is.finite(ai_quiet_quantile) || ai_quiet_quantile <= 0 || ai_quiet_quantile >= 1) stop("ai_quiet_quantile must lie strictly between zero and one.")
    checked <- function(x) {
        if (!valid(x)) stop("Activity Index noise estimation failed; supply a stationary noise variance instead.")
        as.numeric(x)
    }

    samples_per_sec <- max(1L, round(fs_hz))

    if (ai_noise_mode == "window_start") {
        n_total <- nrow(tbl)
        n_noise_samps <- min(round(fs_hz * ai_noise_window_s), n_total)

        if (n_noise_samps < 2 * samples_per_sec) {
            stop("Insufficient data for initial-window Activity Index noise estimation.")
        }

        n_sec <- floor(n_noise_samps / samples_per_sec)

        vals <- vapply(seq_len(n_sec), function(j) {
            ss <- (j - 1L) * samples_per_sec + 1L
            se <- j * samples_per_sec

            (
                stats::var(tbl$ax_g[ss:se], na.rm = TRUE) +
                    stats::var(tbl$ay_g[ss:se], na.rm = TRUE) +
                    stats::var(tbl$az_g[ss:se], na.rm = TRUE)
            ) / 3
        }, numeric(1))

        return(checked(mean(vals, na.rm = TRUE)))
    }

    dvm <- c(0, sqrt(diff(tbl$ax_g)^2 + diff(tbl$ay_g)^2 + diff(tbl$az_g)^2))
    thr <- stats::quantile(dvm, probs = ai_quiet_quantile, na.rm = TRUE, names = FALSE)

    quiet_idx <- dvm <= thr
    sec_id <- floor(as.numeric(tbl$time - tbl$time[1], units = "secs")) + 1L
    quiet_sec <- tapply(quiet_idx, sec_id, mean, na.rm = TRUE)
    keep_sec <- as.integer(names(quiet_sec)[quiet_sec >= 0.8])

    if (!length(keep_sec)) stop("No quiet segments available for Activity Index noise estimation.")

    vv <- lapply(keep_sec, function(s) {
        idx <- sec_id == s
        c(
            stats::var(tbl$ax_g[idx], na.rm = TRUE),
            stats::var(tbl$ay_g[idx], na.rm = TRUE),
            stats::var(tbl$az_g[idx], na.rm = TRUE)
        )
    })

    checked(mean(rowMeans(do.call(rbind, vv), na.rm = TRUE), na.rm = TRUE))
}


accel_metric_ai <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor = "center",
        ai_noise_var = NULL,
        ai_noise_mode = c("supplied", "window_start", "quiet_segments"),
        ai_noise_window_s = 30,
        ai_quiet_quantile = 0.1,
        ai_scale = c("absolute", "relative"),
        ai_epoch_summary = c("sum", "mean")
) {
    tbl <- qc_input_data(tbl)
    ai_noise_mode <- match.arg(ai_noise_mode)
    ai_scale <- match.arg(ai_scale)
    ai_epoch_summary <- match.arg(ai_epoch_summary)

    noise_var <- accel_estimate_ai_noise(
        tbl = tbl,
        fs_hz = fs_hz,
        ai_noise_var = ai_noise_var,
        ai_noise_mode = ai_noise_mode,
        ai_noise_window_s = ai_noise_window_s,
        ai_quiet_quantile = ai_quiet_quantile
    )

    sec_id <- floor(as.numeric(tbl$time - tbl$time[1], units = "secs")) + 1L

    sec_tbl <- tibble::tibble(
        sec_id = sec_id,
        time = tbl$time,
        ax_g = tbl$ax_g,
        ay_g = tbl$ay_g,
        az_g = tbl$az_g
    ) %>%
        dplyr::group_by(sec_id) %>%
        dplyr::summarise(
            time = dplyr::first(time),
            vx = stats::var(ax_g, na.rm = TRUE),
            vy = stats::var(ay_g, na.rm = TRUE),
            vz = stats::var(az_g, na.rm = TRUE),
            .groups = "drop"
        ) %>%
        dplyr::mutate(
            mean_var = (vx + vy + vz) / 3,
            ai_1s = if (ai_scale == "absolute") {
                sqrt(pmax(mean_var - noise_var, 0))
            } else {
                ifelse(noise_var <= 0, NA_real_, sqrt(pmax((mean_var - noise_var) / noise_var, 0)))
            },
            epoch_id = floor(as.numeric(time - time[1], units = "secs") / epoch_s) + 1L
        )

    out <- sec_tbl %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            time = dplyr::case_when(
                anchor == "start" ~ dplyr::first(time),
                anchor == "end" ~ dplyr::last(time),
                TRUE ~ time[ceiling(dplyr::n() / 2)]
            ),
            value = if (ai_epoch_summary == "sum") {
                sum(ai_1s, na.rm = TRUE)
            } else {
                mean(ai_1s, na.rm = TRUE)
            },
            .groups = "drop"
        )

    attr(out, "settings") <- list(
        noise_var_g2 = noise_var,
        noise_source = if (!is.null(ai_noise_var)) "supplied" else ai_noise_mode,
        noise_window_requested_s = if (is.null(ai_noise_var) && ai_noise_mode == "window_start") ai_noise_window_s else NA_real_,
        noise_window_s = if (is.null(ai_noise_var) && ai_noise_mode == "window_start") {
            samples_per_sec <- max(1L, round(fs_hz))
            floor(min(round(fs_hz * ai_noise_window_s), nrow(tbl)) / samples_per_sec) * samples_per_sec / fs_hz
        } else NA_real_,
        quiet_quantile = if (is.null(ai_noise_var) && ai_noise_mode == "quiet_segments") ai_quiet_quantile else NA_real_,
        scale = ai_scale, epoch_summary = ai_epoch_summary,
        base_window_s = 1, epoch_s = epoch_s, fs_hz = fs_hz,
        output_unit = if (ai_scale == "absolute") "g" else "dimensionless")
    attr(out, "ai_noise_var_used") <- noise_var

    out
}


accel_metric_z_angle <- function(
        tbl,
        epoch_s,
        anchor = "center",
        output = c("mean_deg", "sd_deg")
) {
    tbl <- qc_input_data(tbl)
    output <- match.arg(output)

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)
    z_angle <- atan(tbl$az_g / sqrt(tbl$ax_g^2 + tbl$ay_g^2)) * 180 / pi

    tibble::tibble(epoch_id = ep$epoch_id, value = z_angle) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = if (output == "mean_deg") {
                mean(value, na.rm = TRUE)
            } else {
                stats::sd(value, na.rm = TRUE)
            },
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)
}


accel_metric_z_angle_change <- function(
        tbl,
        epoch_s,
        fs_hz,
        anchor = "center",
        median_s = 5,
        output = c("mean_abs_change_deg", "max_abs_change_deg")
) {
    tbl <- qc_input_data(tbl)
    output <- match.arg(output)

    z_angle <- atan(tbl$az_g / sqrt(tbl$ax_g^2 + tbl$ay_g^2)) * 180 / pi

    k <- max(3L, as.integer(round(fs_hz * median_s)))
    if (k %% 2L == 0L) k <- k + 1L

    z_smooth <- as.numeric(stats::runmed(z_angle, k = k, endrule = "median"))
    dz <- c(NA_real_, abs(diff(z_smooth)))

    ep <- accel_make_epoch_index(tbl, epoch_s, anchor)

    tibble::tibble(epoch_id = ep$epoch_id, value = dz) %>%
        dplyr::group_by(epoch_id) %>%
        dplyr::summarise(
            value = if (output == "mean_abs_change_deg") {
                mean(value, na.rm = TRUE)
            } else {
                max(value, na.rm = TRUE)
            },
            .groups = "drop"
        ) %>%
        accel_join_epoch_time(ep$epoch_time)
}


accel_metric_mims <- function(
        tbl,
        epoch_s,
        dynamic_range_g,
        mims_filter_type = "butter",
        mims_cutoffs = c(0.2, 5),
        mims_use_extrapolation = TRUE,
        mims_use_filtering = TRUE,
        mims_combination = "sum",
        mims_allow_truncation = TRUE
) {
    dynamic_range_g <- accel_get_dynamic_range(dynamic_range_g = dynamic_range_g)
    tbl <- qc_input_data(tbl)
    if (!requireNamespace("MIMSunit", quietly = TRUE)) {
        stop("Package 'MIMSunit' is required.")
    }

    x <- data.frame(
        HEADER_TIME_STAMP = tbl$time,
        X = tbl$ax_g,
        Y = tbl$ay_g,
        Z = tbl$az_g
    )

    out <- MIMSunit::custom_mims_unit(
        df = x,
        epoch = paste0(epoch_s, " sec"),
        dynamic_range = c(-dynamic_range_g / 2, dynamic_range_g / 2),
        filter_type = mims_filter_type,
        cutoffs = mims_cutoffs,
        use_extrapolation = mims_use_extrapolation,
        use_filtering = mims_use_filtering,
        combination = mims_combination,
        allow_truncation = mims_allow_truncation,
        output_mims_per_axis = FALSE
    )

    result <- tibble::tibble(
        time = as.POSIXct(out[[1]], tz = "UTC"),
        epoch_id = seq_len(nrow(out)),
        value = out[[2]]
    )
    attr(result, "settings") <- list(
        dynamic_range_g = dynamic_range_g,
        dynamic_range_limits_g = c(-dynamic_range_g / 2, dynamic_range_g / 2),
        range_source = "argument", filter_type = mims_filter_type,
        cutoffs_hz = mims_cutoffs, use_extrapolation = mims_use_extrapolation,
        use_filtering = mims_use_filtering, combination = mims_combination,
        allow_truncation = mims_allow_truncation, epoch_s = epoch_s,
        implementation = "MIMSunit::custom_mims_unit",
        implementation_version = as.character(utils::packageVersion("MIMSunit")))
    result
}


compute_ai_noise_var_from_static <- function(x, window_s = 1, fs_hz = NULL, use_middle_prop = 1) {
    x <- qc_input_data(x)
    positive <- function(z) is.numeric(z) && length(z) == 1L && is.finite(z) && z > 0
    if (!positive(window_s)) stop("window_s must be one finite positive duration in seconds.")
    if (!positive(use_middle_prop) || use_middle_prop > 1) stop("use_middle_prop must lie in (0, 1].")
    if (!is.null(fs_hz) && !positive(fs_hz)) stop("fs_hz must be one finite positive sampling frequency in Hz.")
    req <- c("time", "ax_g", "ay_g", "az_g")
    miss <- setdiff(req, names(x))

    if (length(miss)) {
        stop("Missing columns: ", paste(miss, collapse = ", "))
    }

    if (is.null(fs_hz)) {
        dt <- diff(as.numeric(x$time))
        dt <- dt[is.finite(dt) & dt > 0]
        fs_hz <- 1 / stats::median(dt)
    }

    if (!positive(fs_hz)) stop("Cannot estimate a positive sampling frequency from stationary timestamps.")
    n_per_win <- max(1L, round(fs_hz * window_s))
    if (n_per_win < 2L) stop("Each stationary noise window must contain at least two samples.")
    n <- nrow(x)

    if (use_middle_prop < 1) {
        keep_n <- floor(n * use_middle_prop)
        if (keep_n < n_per_win) stop("Not enough retained data for one static noise window.")
        start_i <- floor((n - keep_n) / 2) + 1L
        end_i <- start_i + keep_n - 1L

        x <- x[start_i:end_i, , drop = FALSE]
        n <- nrow(x)
    }

    n_win <- floor(n / n_per_win)

    if (n_win < 1L) {
        stop("Not enough data for one static noise window.")
    }

    noise_vals <- vapply(seq_len(n_win), function(i) {
        s <- (i - 1L) * n_per_win + 1L
        e <- i * n_per_win

        (
            stats::var(x$ax_g[s:e], na.rm = TRUE) +
                stats::var(x$ay_g[s:e], na.rm = TRUE) +
                stats::var(x$az_g[s:e], na.rm = TRUE)
        ) / 3
    }, numeric(1))

    if (!any(is.finite(noise_vals))) stop("No finite stationary noise-variance estimates are available.")
    list(
        ai_noise_var = mean(noise_vals, na.rm = TRUE),
        ai_noise_sd = sqrt(mean(noise_vals, na.rm = TRUE)),
        window_values = noise_vals,
        n_windows = n_win,
        fs_hz = fs_hz,
        window_s = window_s
    )
}


# ======================================================================
# 6. Core summary computation
# ======================================================================

compute_accel_summaries <- function(
        accel_input,
        measures = c("ENMO", "MAD"),
        epoch_s = 5,
        epoch_anchor = c("center", "start", "end"),
        fs_hz = NULL,
        target_fs = NULL,
        dynamic_range_g = NULL,
        vm_summary = c("mean", "sd", "max", "p95"),
        vm_unit = c("g", "mg"),
        enmo_mg = TRUE,
        mad_mg = TRUE,
        odba_static_dynamic_method = c("centered_running_mean", "low_pass_static_filter", "high_pass_dynamic_filter"),
        odba_stroke_window_rule = c("fixed_3s", "custom_window_s", "stroke_period_1x", "stroke_period_2x", "sensitivity_windows"),
        odba_running_mean_window_s = 3,
        odba_stroke_period_s = NA_real_,
        odba_lowpass_cutoff_hz = 0.2,
        odba_highpass_cutoff_hz = 0.2,
        odba_filter_type = "butterworth",
        odba_filter_order = 4,
        pdba_axes = c("x", "y"),
        odba_unit = c("mg", "g"),
        odba_sensitivity_windows_s = c(1, 2, 3, 5, 10),
        odba_edge_handling = "partial_centered_window",
        odba_missing_data_policy = "mean_na_rm",
        svmg_output = c("g_seconds", "sample_sum_g", "mean_mg", "mean_g"),
        svmg_rectify = TRUE,
        svmbp_cutoffs = c(0.2, 15),
        svmbp_order = 4,
        svmbp_output = c("mean_mg", "mean_g", "sum_mg", "sum_g", "g_seconds"),
        svmbp_nyquist_action = c("stop", "clip"),
        rocam_median_s = 1,
        ai_noise_var = NULL,
        ai_noise_mode = c("supplied", "window_start", "quiet_segments"),
        ai_noise_window_s = 30,
        ai_quiet_quantile = 0.1,
        ai_scale = c("absolute", "relative"),
        ai_epoch_summary = c("sum", "mean"),
        z_angle_output = c("mean_deg", "sd_deg"),
        z_angle_change_median_s = 5,
        z_angle_change_output = c("mean_abs_change_deg", "max_abs_change_deg"),
        mims_filter_type = "butter",
        mims_cutoffs = c(0.2, 5),
        mims_use_extrapolation = TRUE,
        mims_use_filtering = TRUE,
        mims_combination = "sum",
        mims_allow_truncation = TRUE,
        ag_lfe = FALSE,
        ag_preprocess = c("none", "regularise", "paper30", "antialias100"),
        ag_anchor = c("floor_sec", "round_sec"),
        ag_antialias_cutoff_hz = NULL,
        ag_filter_order = 4,
        quiet = FALSE
) {
    load_summary_packages()
    epoch_anchor <- match.arg(epoch_anchor)
    vm_summary <- match.arg(vm_summary)
    vm_unit <- match.arg(vm_unit)
    odba_static_dynamic_method <- match.arg(odba_static_dynamic_method)
    odba_stroke_window_rule <- match.arg(odba_stroke_window_rule)
    odba_unit <- match.arg(odba_unit)
    svmg_output <- match.arg(svmg_output)
    svmbp_output <- match.arg(svmbp_output)
    svmbp_nyquist_action <- match.arg(svmbp_nyquist_action)
    ai_noise_mode <- match.arg(ai_noise_mode)
    ai_scale <- match.arg(ai_scale)
    ai_epoch_summary <- match.arg(ai_epoch_summary)
    z_angle_output <- match.arg(z_angle_output)
    z_angle_change_output <- match.arg(z_angle_change_output)
    ag_preprocess <- match.arg(ag_preprocess)
    ag_anchor <- match.arg(ag_anchor)

    measures <- toupper(measures)

    if ("AG" %in% measures) stop("The AG selector is unavailable in this release; no ActiGraph-count values were computed.", call. = FALSE)
    bad <- setdiff(measures, metric_order())
    if (length(bad)) {
        stop("Unknown measure(s): ", paste(bad, collapse = ", "))
    }

    inp <- accel_unpack_input(accel_input)
    tbl0 <- inp$tbl
    meta <- inp$meta

    fs0 <- accel_get_fs(tbl0, meta = meta, fs_hz = fs_hz, quiet = quiet)
    dr0 <- accel_get_dynamic_range(meta = meta, dynamic_range_g = dynamic_range_g, required = "MIMS" %in% measures)
    range_source <- if (!is.null(dynamic_range_g)) "argument" else if (is.finite(dr0)) "metadata" else "unavailable"

    if (!is.null(target_fs) && is.finite(target_fs) && target_fs > 0 && abs(target_fs - fs0) > 1e-8) {
        tbl0 <- accel_resample_linear(tbl0, target_fs = target_fs)
        fs0 <- target_fs
    }

    res_list <- list()
    ai_noise_var_used <- NA_real_
    ai_settings <- NULL
    mims_settings <- NULL

    if ("VM" %in% measures) {
        res_list$VM <- accel_metric_vm(tbl0, epoch_s, epoch_anchor, vm_summary, vm_unit)
    }

    if ("ENMO" %in% measures) {
        res_list$ENMO <- accel_metric_enmo(tbl0, epoch_s, epoch_anchor, if (enmo_mg) "mg" else "g")
    }

    if ("MAD" %in% measures) {
        res_list$MAD <- accel_metric_mad(tbl0, epoch_s, epoch_anchor, if (mad_mg) "mg" else "g")
    }

    if ("ODBA" %in% measures) {
        res_list$ODBA <- accel_metric_odba(
            tbl0, epoch_s, fs0, epoch_anchor, "ODBA",
            odba_static_dynamic_method, odba_stroke_window_rule,
            odba_running_mean_window_s, odba_stroke_period_s,
            odba_lowpass_cutoff_hz, odba_highpass_cutoff_hz,
            odba_filter_type, odba_filter_order, pdba_axes,
            odba_unit, odba_edge_handling, odba_missing_data_policy
        )
    }

    if ("VEDBA" %in% measures) {
        res_list$VEDBA <- accel_metric_odba(
            tbl0, epoch_s, fs0, epoch_anchor, "VEDBA",
            odba_static_dynamic_method, odba_stroke_window_rule,
            odba_running_mean_window_s, odba_stroke_period_s,
            odba_lowpass_cutoff_hz, odba_highpass_cutoff_hz,
            odba_filter_type, odba_filter_order, pdba_axes,
            odba_unit, odba_edge_handling, odba_missing_data_policy
        )
    }

    if ("PDBA" %in% measures) {
        res_list$PDBA <- accel_metric_odba(
            tbl0, epoch_s, fs0, epoch_anchor, "PDBA",
            odba_static_dynamic_method, odba_stroke_window_rule,
            odba_running_mean_window_s, odba_stroke_period_s,
            odba_lowpass_cutoff_hz, odba_highpass_cutoff_hz,
            odba_filter_type, odba_filter_order, pdba_axes,
            odba_unit, odba_edge_handling, odba_missing_data_policy
        )
    }

    if ("SVMGS" %in% measures) {
        res_list$SVMGS <- accel_metric_svmg(tbl0, epoch_s, fs0, epoch_anchor, "sample_sum_g", svmg_rectify)
    }

    if ("SVMGSEC" %in% measures) {
        res_list$SVMGSEC <- accel_metric_svmg(tbl0, epoch_s, fs0, epoch_anchor, "g_seconds", svmg_rectify)
    }

    if ("SVMGMEAN" %in% measures) {
        res_list$SVMGMEAN <- accel_metric_svmg(tbl0, epoch_s, fs0, epoch_anchor, "mean_mg", svmg_rectify)
    }

    if ("SVMBP" %in% measures) {
        res_list$SVMBP <- accel_metric_svmbp(
            tbl0, epoch_s, fs0, epoch_anchor, svmbp_cutoffs,
            svmbp_order, svmbp_output, svmbp_nyquist_action, quiet
        )
    }

    if ("SVMBP_02_15" %in% measures) {
        res_list$SVMBP_02_15 <- accel_metric_svmbp(
            tbl0, epoch_s, fs0, epoch_anchor, c(0.2, 15),
            svmbp_order, svmbp_output, svmbp_nyquist_action, quiet
        )
    }

    if ("SVMBP_069_10" %in% measures) {
        res_list$SVMBP_069_10 <- accel_metric_svmbp(
            tbl0, epoch_s, fs0, epoch_anchor, c(0.69, 10),
            svmbp_order, svmbp_output, svmbp_nyquist_action, quiet
        )
    }

    if ("ROCAM" %in% measures) {
        res_list$ROCAM <- accel_metric_rocam(tbl0, epoch_s, fs0, epoch_anchor, rocam_median_s)
    }

    if ("AI" %in% measures) {
        ai_tbl <- accel_metric_ai(
            tbl0, epoch_s, fs0, epoch_anchor,
            ai_noise_var, ai_noise_mode, ai_noise_window_s,
            ai_quiet_quantile, ai_scale, ai_epoch_summary
        )

        res_list$AI <- ai_tbl
        ai_noise_var_used <- attr(ai_tbl, "ai_noise_var_used")
        ai_settings <- attr(ai_tbl, "settings")
    }

    if ("ZANGLE" %in% measures) {
        res_list$ZANGLE <- accel_metric_z_angle(tbl0, epoch_s, epoch_anchor, z_angle_output)
    }

    if ("ZANGLE_CHANGE" %in% measures) {
        res_list$ZANGLE_CHANGE <- accel_metric_z_angle_change(
            tbl0, epoch_s, fs0, epoch_anchor,
            z_angle_change_median_s, z_angle_change_output
        )
    }

    if ("MIMS" %in% measures) {
        res_list$MIMS <- accel_metric_mims(
            tbl0, epoch_s, dr0,
            mims_filter_type, mims_cutoffs,
            mims_use_extrapolation, mims_use_filtering,
            mims_combination, mims_allow_truncation
        )
        mims_settings <- attr(res_list$MIMS, "settings")
        mims_settings$range_source <- range_source
    }



    odba_sensitivity <- if (
        odba_stroke_window_rule == "sensitivity_windows" &&
            any(measures %in% c("ODBA", "VEDBA", "PDBA"))
    ) {
        accel_odba_sensitivity_summary(
            tbl = tbl0,
            epoch_s = epoch_s,
            fs_hz = fs0,
            anchor = epoch_anchor,
            metrics = intersect(measures, c("ODBA", "VEDBA", "PDBA")),
            windows_s = odba_sensitivity_windows_s,
            static_dynamic_method = odba_static_dynamic_method,
            stroke_period_s = odba_stroke_period_s,
            lowpass_cutoff_hz = odba_lowpass_cutoff_hz,
            highpass_cutoff_hz = odba_highpass_cutoff_hz,
            filter_type = odba_filter_type,
            filter_order = odba_filter_order,
            pdba_axes = pdba_axes,
            out_unit = odba_unit,
            edge_handling = odba_edge_handling,
            missing_data_policy = odba_missing_data_policy
        )
    } else {
        tibble::tibble()
    }

    bandpass_settings <- lapply(res_list[intersect(names(res_list), c("SVMBP", "SVMBP_02_15", "SVMBP_069_10"))], attr, "settings")
    bp_unit <- switch(svmbp_output, mean_mg = "mg", mean_g = "g",
        sum_mg = "mg samples per epoch", sum_g = "g samples per epoch", g_seconds = "g seconds per epoch")
    metric_units <- c(VM = vm_unit, ENMO = if (enmo_mg) "mg" else "g",
        MAD = if (mad_mg) "mg" else "g", ODBA = odba_unit, VEDBA = odba_unit,
        PDBA = odba_unit, SVMGS = "g samples per epoch", SVMGSEC = "g seconds per epoch",
        SVMGMEAN = "mg", SVMBP = bp_unit, SVMBP_02_15 = bp_unit, SVMBP_069_10 = bp_unit,
        ROCAM = "g/sample change", AI = if (ai_scale == "absolute") "g" else "dimensionless",
        ZANGLE = "degrees", ZANGLE_CHANGE = "degrees", MIMS = "MIMS-units per epoch")
    metric_units <- metric_units[names(res_list)]

    wide_list <- Map(function(df, nm) {
        out <- tibble::as_tibble(df)
        out <- out[, intersect(c("time", "value"), names(out)), drop = FALSE]
        names(out)[names(out) == "value"] <- nm
        out
    }, res_list, names(res_list))

    results_wide <- Reduce(function(x, y) dplyr::full_join(x, y, by = "time"), wide_list)

    results_long <- dplyr::bind_rows(lapply(names(res_list), function(nm) {
        tibble::tibble(
            time = res_list[[nm]]$time,
            measure = nm,
            value = res_list[[nm]]$value
        )
    }))

    invisible(list(
        data_wide = results_wide,
        data_long = results_long,
        settings = list(
            source_type = inp$source_type,
            measures = measures,
            metric_units = metric_units,
            bandpass = bandpass_settings,
            epoch_s = epoch_s,
            epoch_anchor = epoch_anchor,
            fs_hz = fs0,
            wear_location = first_present(meta$acquisition$wear_location, meta$acquisition$wear_site, NA_character_),
            device_model = first_present(meta$acquisition$device_model, NA_character_),
            sampling_rate_hz = fs0,
            input_units = "g",
            calibration_state = first_present(meta$processing$signal_pipeline, meta$processing$calibration_state, "source_scale_as_parsed"),
            axis_labels = list(x = "ax_g", y = "ay_g", z = "az_g"),
            software_version = "mjt_processing v1.0.0",
            target_fs = target_fs,
            dynamic_range_g = dr0,
            dynamic_range_source = range_source,
            dynamic_range_limits_g = if (is.finite(dr0)) c(-dr0 / 2, dr0 / 2) else c(NA_real_, NA_real_),
            mims = mims_settings,
            ai = ai_settings,
            odba = list(
                static_dynamic_method = odba_static_dynamic_method,
                filter_type = odba_filter_type,
                filter_order = odba_filter_order,
                lowpass_cutoff_hz = odba_lowpass_cutoff_hz,
                highpass_cutoff_hz = odba_highpass_cutoff_hz,
                running_mean_window_s = accel_resolve_odba_window_s(
                    odba_stroke_window_rule,
                    odba_running_mean_window_s,
                    odba_stroke_period_s
                ),
                requested_running_mean_window_s = odba_running_mean_window_s,
                stroke_period_s = odba_stroke_period_s,
                stroke_window_rule = odba_stroke_window_rule,
                sensitivity_windows_s = odba_sensitivity_windows_s,
                sensitivity_summary = odba_sensitivity,
                pdba_axes = unique(tolower(as.character(pdba_axes))),
                epoch_length_s = epoch_s,
                summary_statistic = "epoch mean",
                edge_handling = odba_edge_handling,
                missing_data_policy = odba_missing_data_policy,
                output_unit = odba_unit
            ),
            ai_noise_var_input = ai_noise_var,
            ai_noise_var_used = ai_noise_var_used,
            ag_preprocess = ag_preprocess,
            ag_antialias_cutoff_hz = ag_antialias_cutoff_hz
        )
    ))
}
