# ======================================================================
# Dynamic trial clipper (time-based, sampling-rate agnostic)
# - Input: accel_tbl or bundle(list(data=accel_tbl,...))
# - Output: list(full=accel_tbl, stages=list, schedule=tibble, meta=list)
# ======================================================================

clip_dynamic_stages <- function(x,
                                start_utc,
                                n_stages,
                                stage_min,
                                buffer_min,
                                rpm_start,
                                rpm_step,
                                trim_start_min,
                                trim_end_min,
                                keep_empty = FALSE,
                                verbose = FALSE,
                                time_offset_s = 0) {                 # seconds to shift schedule

    if (missing(n_stages) || missing(stage_min) || missing(buffer_min) ||
        missing(rpm_start) || missing(rpm_step) || missing(trim_start_min) || missing(trim_end_min)) {
        stop("Specify n_stages, stage_min, buffer_min, rpm_start, rpm_step, trim_start_min and trim_end_min for the experiment.")
    }
    values <- list(n_stages, stage_min, buffer_min, rpm_start, rpm_step, trim_start_min, trim_end_min)
    if (!all(vapply(values, function(z) is.numeric(z) && length(z) == 1L && is.finite(z), logical(1))) ||
        n_stages != as.integer(n_stages)) stop("Schedule parameters must be finite numeric scalars; n_stages must be an integer.")
    x <- qc_input_data(x)
    stopifnot(is.data.frame(x))

    if (!inherits(start_utc, "POSIXct")) start_utc <- as.POSIXct(start_utc, tz = "UTC")
    stopifnot(inherits(start_utc, "POSIXct"))
    attr(start_utc, "tzone") <- "UTC"

    start_utc <- start_utc + as.numeric(time_offset_s)              # apply offset to schedule anchor

    stopifnot(inherits(x$time, "POSIXct"))
    attr(x$time, "tzone") <- "UTC"
    x <- x[order(x$time), ]

    stopifnot(n_stages > 0L, stage_min > 0, buffer_min >= 0, trim_start_min >= 0, trim_end_min >= 0)
    stopifnot((trim_start_min + trim_end_min) < stage_min)

    m2s <- function(m) as.numeric(m) * 60

    idx <- seq_len(n_stages)
    rpm <- rpm_start + (idx - 1L) * rpm_step

    stage_start <- start_utc + (idx - 1L) * (m2s(stage_min) + m2s(buffer_min))
    stage_end   <- stage_start + m2s(stage_min)

    trim_start <- stage_start + m2s(trim_start_min)
    trim_end   <- stage_end   - m2s(trim_end_min)

    schedule <- tibble::tibble(
        stage_index = idx,
        rpm = rpm,
        stage_min = stage_min,
        buffer_min = buffer_min,
        trim_start_min = trim_start_min,
        trim_end_min = trim_end_min,
        start_raw_utc = stage_start,
        end_raw_utc   = stage_end,
        start_trim_utc = trim_start,
        end_trim_utc   = trim_end
    )

    full_start <- min(stage_start)
    full_end   <- max(stage_end)

    clip_accel_tbl <- function(a, t1, t2) {
        m <- accel_meta(a)
        out <- a[a$time >= t1 & a$time < t2, , drop = FALSE]
        attr(out, "meta") <- m
        class(out) <- c("accel_tbl", setdiff(class(out), "accel_tbl"))
        if (exists("attach_qc", mode = "function")) {
            out <- attach_qc(out, scope = paste("dynamic clip", format(t1, tz = "UTC"),
                "to", format(t2, tz = "UTC"), "UTC; end exclusive"))
        } else {
            m$processing$qc <- NULL
            attr(out, "meta") <- m
        }
        out
    }

    full <- clip_accel_tbl(x, full_start, full_end)

    stages <- vector("list", n_stages)
    names(stages) <- paste0("rpm_", rpm)

    for (i in seq_len(n_stages)) {
        yi <- clip_accel_tbl(x, schedule$start_trim_utc[i], schedule$end_trim_utc[i])
        if (!keep_empty && nrow(yi) == 0L) {
            stages[i] <- list(NULL)                                 # keep list length stable
        } else {
            stages[i] <- list(yi)
        }
    }

    if (isTRUE(verbose)) {
        message("[clip_dynamic_stages] full: ", nrow(full), " samples")
        nn <- vapply(stages, function(z) if (is.null(z)) 0L else nrow(z), integer(1))
        message("[clip_dynamic_stages] stage samples: ", paste(nn, collapse = ", "))
        message("[clip_dynamic_stages] time span in x: ",
                format(min(x$time)), " to ", format(max(x$time)))
        message("[clip_dynamic_stages] schedule full: ",
                format(full_start), " to ", format(full_end))
    }

    list(full = full, stages = stages, schedule = schedule, meta = accel_meta(full))
}


# ======================================================================
# Reference-based dynamic metrology and optional VM calibration
# Clip bundles contain full, stages, schedule and meta elements.
# Calibration and filtering are explicit processing choices, not automatic steps.
# ======================================================================

# =============================================================================
# Core utilities
# =============================================================================

dm_vm <- function(ax, ay, az) {                                                     # Compute vector magnitude
    sqrt(ax^2 + ay^2 + az^2)
}

dm_get_time <- function(df) {                                                       # Extract canonical time
    df$time
}

dm_get_axes <- function(df) {                                                       # Extract canonical axes
    list(ax = df$ax_g, ay = df$ay_g, az = df$az_g)
}

dm_parse_rpm <- function(x) {                                                       # Parse rpm from stage name
    suppressWarnings(as.numeric(gsub("[^0-9.]+", "", x)))
}

dm_estimate_fs <- function(t) {                                                     # Estimate sampling frequency
    dt <- stats::median(diff(as.numeric(t)), na.rm = TRUE)
    if (!is.finite(dt) || dt <= 0) return(NA_real_)
    1 / dt
}


dm_match_length <- function(x, n) {                                                 # Index-based length matching
    if (length(x) == n) return(x)
    if (!length(x) || !is.finite(n) || n < 1) return(rep(NA_real_, n))
    x[round(seq(1, length(x), length.out = n))]
}

dm_epoch_bin <- function(t, win_s) {                                                # Create epoch bins
    floor(as.numeric(t - t[1]) / win_s)
}

dm_downsample_idx <- function(n, max_n) {                                           # Uniform downsample indices
    if (!is.finite(max_n) || max_n <= 0 || n <= max_n) return(seq_len(n))
    round(seq(1, n, length.out = max_n))
}

dm_fsr_from_meta <- function(clips) {                                               # Resolve full-scale range
    m <- clips$meta
    if (is.null(m) && !is.null(clips$full) && exists("accel_meta")) m <- accel_meta(clips$full)
    v <- m$acquisition$full_scale_range_g
    if (is.numeric(v) && length(v) == 1L && is.finite(v) && v > 0) as.numeric(v) else NA_real_
}

dm_pick_signal <- function(axes, which) {                                           # Select alignment signal
    if (which == "ax") return(axes$ax)
    if (which == "ay") return(axes$ay)
    if (which == "az") return(axes$az)
    dm_vm(axes$ax, axes$ay, axes$az)
}

dm_resample_to_hz <- function(t, y, target_hz) {                                    # Resample to uniform grid
    tt <- as.numeric(t)
    ok <- is.finite(tt) & is.finite(y)
    tt <- tt[ok]
    y <- y[ok]
    if (length(tt) < 4) return(list(t = numeric(0), y = numeric(0)))
    tt <- tt - tt[1]
    t_out <- seq(0, max(tt), by = 1 / target_hz)
    y_out <- stats::approx(tt, y, xout = t_out, rule = 2)$y
    list(t = t_out, y = y_out)
}

dm_xcorr_lag_s <- function(y_test, y_ref, fs_hz, max_lag_s) {                      # Estimate lag by cross-correlation
    if (length(y_test) < 32 || length(y_ref) < 32) return(list(lag_s = NA_real_, df = NULL))
    yt <- as.numeric(scale(y_test))
    yr <- as.numeric(scale(y_ref))
    lag_max <- as.integer(max_lag_s * fs_hz)
    cc <- stats::ccf(yt, yr, lag.max = lag_max, plot = FALSE)
    lag_s <- as.numeric(cc$lag) / fs_hz
    acf <- as.numeric(cc$acf)
    k <- which.max(acf)
    list(lag_s = lag_s[k], df = data.frame(lag_s = lag_s, acf = acf))
}

dm_fft_summaries <- function(vm, fs_hz) {                                          # FFT summaries
    v <- vm - mean(vm, na.rm = TRUE)
    v <- stats::na.omit(v)
    if (length(v) < 16 || !is.finite(fs_hz)) {
        return(list(dom_hz = NA_real_, dom_mag = NA_real_, noise_p = NA_real_, snr = NA_real_))
    }
    f <- fft(v)
    mag <- Mod(f[1:floor(length(f) / 2)])
    hz <- seq(0, fs_hz / 2, length.out = length(mag))
    k <- which.max(mag)
    tot_p <- sum(mag^2, na.rm = TRUE)
    dom_p <- mag[k]^2
    noise_p <- max(tot_p - dom_p, 0)
    snr <- if (noise_p > 0) dom_p / noise_p else NA_real_
    list(dom_hz = hz[k], dom_mag = mag[k], noise_p = noise_p, snr = snr)
}

dm_entropy_feats <- function(vm, compute_entropy = TRUE, m = 2, r = NULL, tau = 1) { # Entropy features
    if (!isTRUE(compute_entropy)) return(list(sampen = NA_real_, apen = NA_real_))
    if (!requireNamespace("TSEntropies", quietly = TRUE)) return(list(sampen = NA_real_, apen = NA_real_))
    x <- as.numeric(scale(vm, center = TRUE, scale = TRUE))
    rr <- if (is.null(r)) 0.2 * stats::sd(x, na.rm = TRUE) else r
    se <- tryCatch(TSEntropies::SampEn(x, dim = m, r = rr, lag = tau), error = function(e) NA_real_)
    ae <- tryCatch(TSEntropies::ApEn(x, dim = m, r = rr, lag = tau), error = function(e) NA_real_)
    list(sampen = se, apen = ae)
}

dm_aicc_lm <- function(fit) {                                                       # AICc for lm
    n <- stats::nobs(fit)
    k <- attr(stats::logLik(fit), "df")
    aic <- stats::AIC(fit)
    if (!is.finite(n) || n <= k + 1) return(NA_real_)
    aic + (2 * k * (k + 1)) / (n - k - 1)
}

dm_rmse_lm <- function(fit) {                                                       # RMSE for lm
    sqrt(mean(stats::residuals(fit)^2, na.rm = TRUE))
}

# =============================================================================
# Calibration fitting and application
# =============================================================================

dm_make_calibration_pairs <- function(test_clips,
                                      ref_clips,
                                      window_s = 5,
                                      fit_unit = c("window", "sample")) {          # Build trial-level calibration pairs
    fit_unit <- match.arg(fit_unit)
    stage_names <- intersect(names(test_clips$stages), names(ref_clips$stages))
    if (!length(stage_names)) stop("No overlapping stages for calibration.")
    pair_list <- lapply(stage_names, function(nm) {
        s_test <- test_clips$stages[[nm]]
        s_ref <- ref_clips$stages[[nm]]
        t_test <- dm_get_time(s_test)
        a_test <- dm_get_axes(s_test)
        a_ref <- dm_get_axes(s_ref)
        vm_test <- dm_vm(a_test$ax, a_test$ay, a_test$az)
        vm_ref <- dm_vm(a_ref$ax, a_ref$ay, a_ref$az)
        vm_ref_m <- dm_match_length(vm_ref, length(vm_test))
        d <- data.frame(stage = nm, rpm = dm_parse_rpm(nm), t = as.numeric(t_test), test_vm = vm_test, ref_vm = vm_ref_m)
        d[is.finite(d$t) & is.finite(d$test_vm) & is.finite(d$ref_vm), ]
    })
    d <- dplyr::bind_rows(pair_list)
    if (!nrow(d)) return(data.frame(test_vm = numeric(0), ref_vm = numeric(0)))
    if (fit_unit == "sample") return(d[, c("test_vm", "ref_vm"), drop = FALSE])
    d$bin <- floor((d$t - min(d$t, na.rm = TRUE)) / window_s)
    out <- stats::aggregate(cbind(test_vm, ref_vm) ~ bin, data = d, FUN = mean, na.rm = TRUE)
    out[, c("test_vm", "ref_vm"), drop = FALSE]
}

dm_fit_vm_calibration <- function(test_clips,
                                  ref_clips,
                                  window_s = 5,
                                  select_by = c("AIC", "AICc", "BIC", "linear"),
                                  fit_unit = c("window", "sample"),
                                  direction = c("ref_on_test", "test_on_ref")) {   # Fit linear/quadratic calibration
    select_by <- match.arg(select_by)
    fit_unit <- match.arg(fit_unit)
    direction <- match.arg(direction)
    pairs <- dm_make_calibration_pairs(test_clips, ref_clips, window_s = window_s, fit_unit = fit_unit)
    x <- if (direction == "ref_on_test") pairs$test_vm else pairs$ref_vm
    y <- if (direction == "ref_on_test") pairs$ref_vm else pairs$test_vm
    d <- data.frame(x = x, y = y)
    d <- d[is.finite(d$x) & is.finite(d$y), ]
    empty <- tibble::tibble(
        vm_calibration_direction = direction,
        vm_calibration_select_by = select_by,
        vm_calibration_fit_unit = fit_unit,
        vm_calibration_model = NA_character_,
        vm_calibration_n = nrow(d),
        vm_calibration_intercept = NA_real_,
        vm_calibration_slope = NA_real_,
        vm_calibration_quadratic = NA_real_,
        vm_calibration_aic_linear = NA_real_,
        vm_calibration_aic_quadratic = NA_real_,
        vm_calibration_delta_aic_linear_minus_quadratic = NA_real_,
        vm_calibration_aicc_linear = NA_real_,
        vm_calibration_aicc_quadratic = NA_real_,
        vm_calibration_bic_linear = NA_real_,
        vm_calibration_bic_quadratic = NA_real_,
        vm_calibration_rmse_linear = NA_real_,
        vm_calibration_rmse_quadratic = NA_real_
    )
    if (nrow(d) < 5 || length(unique(d$x)) < 3) {
        return(list(summary = empty, fit_linear = NULL, fit_quadratic = NULL, chosen_fit = NULL, pairs = pairs))
    }
    fit_l <- stats::lm(y ~ x, data = d)
    fit_q <- stats::lm(y ~ x + I(x^2), data = d)
    aic_l <- stats::AIC(fit_l)
    aic_q <- stats::AIC(fit_q)
    aicc_l <- dm_aicc_lm(fit_l)
    aicc_q <- dm_aicc_lm(fit_q)
    bic_l <- stats::BIC(fit_l)
    bic_q <- stats::BIC(fit_q)
    rmse_l <- dm_rmse_lm(fit_l)
    rmse_q <- dm_rmse_lm(fit_q)
    chosen <- switch(
        select_by,
        AIC = if (aic_q < aic_l) "quadratic" else "linear",
        AICc = if (is.finite(aicc_q) && aicc_q < aicc_l) "quadratic" else "linear",
        BIC = if (bic_q < bic_l) "quadratic" else "linear",
        linear = "linear"
    )
    chosen_fit <- if (chosen == "quadratic") fit_q else fit_l
    cf <- stats::coef(chosen_fit)
    summary <- tibble::tibble(
        vm_calibration_direction = direction,
        vm_calibration_select_by = select_by,
        vm_calibration_fit_unit = fit_unit,
        vm_calibration_model = chosen,
        vm_calibration_n = nrow(d),
        vm_calibration_intercept = unname(cf[1]),
        vm_calibration_slope = unname(cf[2]),
        vm_calibration_quadratic = if (chosen == "quadratic") unname(cf[3]) else 0,
        vm_calibration_aic_linear = aic_l,
        vm_calibration_aic_quadratic = aic_q,
        vm_calibration_delta_aic_linear_minus_quadratic = aic_l - aic_q,
        vm_calibration_aicc_linear = aicc_l,
        vm_calibration_aicc_quadratic = aicc_q,
        vm_calibration_bic_linear = bic_l,
        vm_calibration_bic_quadratic = bic_q,
        vm_calibration_rmse_linear = rmse_l,
        vm_calibration_rmse_quadratic = rmse_q
    )
    list(summary = summary, fit_linear = fit_l, fit_quadratic = fit_q, chosen_fit = chosen_fit, pairs = pairs)
}

dm_validate_vm_calibration <- function(cal_row) {
    coefficients <- c("vm_calibration_intercept", "vm_calibration_slope", "vm_calibration_quadratic")
    if (!is.list(cal_row) || !all(coefficients %in% names(cal_row)) ||
        (is.data.frame(cal_row) && nrow(cal_row) != 1L) ||
        !all(vapply(cal_row[coefficients], function(z) is.numeric(z) && length(z) == 1L && is.finite(z), logical(1)))) {
        stop("cal_row must contain one finite numeric intercept, slope and quadratic coefficient; use zero for the quadratic coefficient of a linear model.", call. = FALSE)
    }
    direction <- cal_row$vm_calibration_direction
    if (!is.null(direction) && (length(direction) != 1L || is.na(direction) || direction != "ref_on_test")) {
        stop("Calibration application requires ref_on_test coefficients mapping test VM to reference VM.", call. = FALSE)
    }
    invisible(TRUE)
}

dm_apply_vm_calibration_tbl <- function(df, cal_row) {
    dm_validate_vm_calibration(cal_row)
    if (is.list(df) && !is.data.frame(df) && !is.null(df$stages)) {
        return(dm_apply_vm_calibration_bundle(df, cal_row))
    }
    original <- df
    df <- qc_input_data(df)
    out <- df
    vm_raw <- dm_vm(out$ax_g, out$ay_g, out$az_g)
    b0 <- cal_row$vm_calibration_intercept[1]
    b1 <- cal_row$vm_calibration_slope[1]
    b2 <- cal_row$vm_calibration_quadratic[1]
    vm_cal <- b0 + b1 * vm_raw + b2 * vm_raw^2
    vm_cal <- ifelse(is.finite(vm_cal), pmax(vm_cal, 0), NA_real_)
    scale <- ifelse(is.finite(vm_raw) & vm_raw > 0 & is.finite(vm_cal), vm_cal / vm_raw, 1)
    out$ax_g <- out$ax_g * scale
    out$ay_g <- out$ay_g * scale
    out$az_g <- out$az_g * scale
    attr(out, "meta") <- attr(df, "meta")
    class(out) <- class(df)
    out <- invalidate_qc(out)
    meta <- accel_meta(out)
    if (is.null(meta)) meta <- list()
    if (is.null(meta$processing)) meta$processing <- list()
    row <- lapply(cal_row, function(z) z[1L])
    meta$processing$vm_calibration <- row
    meta$processing$signal_pipeline <- "calibrated"
    meta$processing$calibration_state <- "dynamic_vm_calibrated"
    meta$processing$history <- c(meta$processing$history, list(list(
        operation = "dynamic_vm_calibration", coefficients = row,
        direction = "ref_on_test", qc_status = "invalidated")))
    attr(out, "meta") <- meta
    qc_restore_input(original, out, clear_qc = TRUE)
}

dm_apply_vm_calibration_bundle <- function(clips, cal_row) {
    dm_validate_vm_calibration(cal_row)
    if (is.data.frame(clips)) return(dm_apply_vm_calibration_tbl(clips, cal_row))
    if (!is.list(clips)) stop("clips must be an acceleration table, parser bundle or dynamic stage bundle.", call. = FALSE)
    out <- clips
    update <- function(data) {
        if (is.null(data)) return(NULL)
        if (is.null(attr(data, "meta")) && !is.null(clips$meta)) attr(data, "meta") <- clips$meta
        dm_apply_vm_calibration_tbl(data, cal_row)
    }
    for (field in c("full", "data")) if (!is.null(out[[field]])) out[[field]] <- update(out[[field]])
    if (!is.null(out$stages)) {
        if (!is.list(out$stages)) stop("stages must be a list of acceleration tables.", call. = FALSE)
        out$stages <- lapply(out$stages, update)
    }
    candidates <- c(list(out$full, out$data), out$stages)
    present <- vapply(candidates, is.data.frame, logical(1))
    if (!any(present)) stop("The bundle contains no acceleration table to calibrate.", call. = FALSE)
    out$meta <- accel_meta(candidates[[which(present)[1L]]])
    out$qc <- NULL
    out
}


# =============================================================================
# Dynamic metrology report
# =============================================================================

# Direct response/error calculation, shared by stage and pooled-trial assessment.
# Numeric inputs are VM in g; table/bundle inputs are converted to sample-level VM.
m_dynamic_response <- function(test, reference, axis_fsr_g) {
    if (!is.numeric(axis_fsr_g) || length(axis_fsr_g) != 1L || !is.finite(axis_fsr_g) || axis_fsr_g <= 0) {
        stop("axis_fsr_g must be one finite positive peak-to-peak axis span in g.")
    }
    vm <- function(x) {
        if (is.numeric(x)) return(x)
        x <- qc_input_data(x)
        dm_vm(x$ax_g, x$ay_g, x$az_g)
    }
    vm_test <- vm(test)
    vm_ref_m <- dm_match_length(vm(reference), length(vm_test))
    fit <- stats::lm(vm_test ~ vm_ref_m)
    predicted <- stats::predict(fit)
    residual <- max(abs(vm_test - predicted), na.rm = TRUE)
    slope <- unname(stats::coef(fit)[2])
    list(vm_bias_vs_reference = mean(vm_test - vm_ref_m, na.rm = TRUE),
         response_slope = slope,
         response_intercept = unname(stats::coef(fit)[1]),
         scale_factor_error = if (is.finite(slope)) slope - 1 else NA_real_,
         linearity_error_vs_reference = residual / (sqrt(3) * axis_fsr_g) * 100,
         composite_error = residual / (sqrt(3) * axis_fsr_g / 2) * 100,
         maximum_absolute_residual_g = residual,
         predicted_vm_g = predicted)
}

dynamic_metrology_report <- function(test_clips,
                                     ref_clips,
                                     test_axis_fsr_g = NULL,
                                     ref_axis_fsr_g = NULL,
                                     window_s = 5,
                                     epoch_time = c("end", "center", "start"),
                                     compute_entropy = TRUE,
                                     entropy_m = 2,
                                     entropy_r = NULL,
                                     entropy_tau = 1,
                                     verbose = FALSE,
                                     progress = TRUE,
                                     add_plot = TRUE,
                                     inspect_alignment = TRUE,
                                     align_hz = 10,
                                     align_max_lag_s = 7200,
                                     align_by = c("vm", "ax", "ay", "az"),
                                     align_plot_stages_n = 3,
                                     compute_stage_xcorr = FALSE,
                                     comp_plot_max_n = 20000L,
                                     comp_plot_ylim = NULL) {                 # Compute dynamic metrics
    epoch_time <- match.arg(epoch_time)
    align_by <- match.arg(align_by)
    stopifnot(is.list(test_clips), is.list(ref_clips))
    stopifnot(!is.null(test_clips$stages), !is.null(ref_clips$stages))
    resolve_range <- function(value, clips, label, required) {
        valid <- function(z) is.numeric(z) && length(z) == 1L && is.finite(z) && z > 0
        if (!is.null(value)) {
            if (!valid(value)) stop(label, " must be one finite positive peak-to-peak axis span in g.")
            return(as.numeric(value))
        }
        value <- dm_fsr_from_meta(clips)
        if (valid(value)) return(as.numeric(value))
        if (required) stop("Dynamic normalised errors require test_axis_fsr_g or valid measurement-range metadata.")
        NA_real_
    }
    test_range_source <- if (!is.null(test_axis_fsr_g)) "argument" else "metadata"
    ref_range_source <- if (!is.null(ref_axis_fsr_g)) "argument" else "metadata"
    test_axis_fsr_g <- resolve_range(test_axis_fsr_g, test_clips, "test_axis_fsr_g", TRUE)
    ref_axis_fsr_g <- resolve_range(ref_axis_fsr_g, ref_clips, "ref_axis_fsr_g", FALSE)
    if (!is.finite(ref_axis_fsr_g)) ref_range_source <- "unavailable"
    fsr_vm_test_g <- sqrt(3) * test_axis_fsr_g
    fsr_vm_ref_g <- sqrt(3) * ref_axis_fsr_g
    half_fsr_vm_test_g <- fsr_vm_test_g / 2
    stage_names <- intersect(names(test_clips$stages), names(ref_clips$stages))
    if (!length(stage_names)) stop("No overlapping stage names between test and reference clips.")
    pb <- NULL
    if (isTRUE(progress)) pb <- utils::txtProgressBar(min = 0, max = length(stage_names), style = 3)
    out_rows <- vector("list", length(stage_names))
    for (i in seq_along(stage_names)) {
        if (isTRUE(progress)) utils::setTxtProgressBar(pb, i)
        nm <- stage_names[i]
        s_test <- test_clips$stages[[nm]]
        s_ref <- ref_clips$stages[[nm]]
        t_test <- dm_get_time(s_test)
        a_test <- dm_get_axes(s_test)
        a_ref <- dm_get_axes(s_ref)
        fs_test <- dm_estimate_fs(t_test)
        fs_ref <- dm_estimate_fs(dm_get_time(s_ref))
        vm_test <- dm_vm(a_test$ax, a_test$ay, a_test$az)
        vm_ref <- dm_vm(a_ref$ax, a_ref$ay, a_ref$az)
        vm_ref_m <- dm_match_length(vm_ref, length(vm_test))
        vm_mean <- mean(vm_test, na.rm = TRUE)
        vm_sd <- stats::sd(vm_test, na.rm = TRUE)
        vm_mad <- mean(abs(vm_test - vm_mean), na.rm = TRUE)
        vm_cv <- if (is.finite(vm_mean) && vm_mean != 0) vm_sd / vm_mean else NA_real_
        sig_pow <- mean(vm_test^2, na.rm = TRUE)
        response <- m_dynamic_response(vm_test, vm_ref_m, test_axis_fsr_g)
        vm_bias <- response$vm_bias_vs_reference
        response_slope <- response$response_slope
        response_intercept <- response$response_intercept
        linearity_error <- response$linearity_error_vs_reference
        scale_factor_error <- response$scale_factor_error
        snr_t <- if (is.finite(vm_sd) && vm_sd > 0) vm_mean / vm_sd else NA_real_
        fd <- dm_fft_summaries(vm_test, fs_test)
        ent <- dm_entropy_feats(vm_test, compute_entropy, entropy_m, entropy_r, entropy_tau)
        ax_abs <- max(abs(a_test$ax), na.rm = TRUE)
        ay_abs <- max(abs(a_test$ay), na.rm = TRUE)
        az_abs <- max(abs(a_test$az), na.rm = TRUE)
        vm_abs <- max(abs(vm_test), na.rm = TRUE)
        fs_util_axis <- max(ax_abs, ay_abs, az_abs) / test_axis_fsr_g
        fs_util_vm <- vm_abs / fsr_vm_test_g
        b <- dm_epoch_bin(t_test, window_s)
        ep_vm <- as.numeric(tapply(vm_test, b, mean, na.rm = TRUE))
        rep_cv <- if (length(ep_vm) >= 2 && mean(ep_vm, na.rm = TRUE) != 0) stats::sd(ep_vm, na.rm = TRUE) / mean(ep_vm, na.rm = TRUE) else NA_real_
        stage_lag_s <- NA_real_
        if (isTRUE(inspect_alignment) && isTRUE(compute_stage_xcorr) && is.finite(align_hz) && align_hz > 0) {
            y_test <- dm_pick_signal(a_test, align_by)
            y_ref <- dm_pick_signal(a_ref, align_by)
            rs_t <- dm_resample_to_hz(t_test, y_test, align_hz)
            rs_r <- dm_resample_to_hz(dm_get_time(s_ref), y_ref, align_hz)
            if (length(rs_t$y) && length(rs_r$y)) {
                m <- min(length(rs_t$y), length(rs_r$y))
                xcl <- dm_xcorr_lag_s(rs_t$y[1:m], rs_r$y[1:m], align_hz, align_max_lag_s)
                stage_lag_s <- xcl$lag_s
            }
        }
        out_rows[[i]] <- tibble::tibble(
            stage = nm,
            rpm = dm_parse_rpm(nm),
            fs_hz_test = fs_test,
            fs_hz_ref = fs_ref,
            n = length(vm_test),
            vm_mean = vm_mean,
            vm_standard_deviation = vm_sd,
            vm_mean_amplitude_deviation = vm_mad,
            vm_coefficient_of_variation = vm_cv,
            signal_power_vm = sig_pow,
            dominant_frequency = fd$dom_hz,
            dominant_frequency_magnitude = fd$dom_mag,
            sample_entropy = ent$sampen,
            approximate_entropy = ent$apen,
            vm_bias_vs_reference = vm_bias,
            linearity_error_vs_reference = linearity_error,
            snr_time_domain = snr_t,
            snr_frequency_domain = fd$snr,
            repeatability_error_cv = rep_cv,
            full_scale_utilisation_axis = fs_util_axis,
            full_scale_utilisation_vm = fs_util_vm,
            scale_factor_error = scale_factor_error,
            response_slope = response_slope,
            response_intercept = response_intercept,
            dead_band = NA_real_,
            activation_threshold = NA_real_,
            alignment_lag_s = stage_lag_s
        )
    }
    if (isTRUE(progress)) close(pb)
    stages_tbl <- dplyr::bind_rows(out_rows)
    all_vm <- numeric(0)
    all_ref <- numeric(0)
    for (nm in stage_names) {
        a_test <- dm_get_axes(test_clips$stages[[nm]])
        a_ref <- dm_get_axes(ref_clips$stages[[nm]])
        all_vm <- c(all_vm, dm_vm(a_test$ax, a_test$ay, a_test$az))
        all_ref <- c(all_ref, dm_vm(a_ref$ax, a_ref$ay, a_ref$az))
    }
    all_ref_m <- dm_match_length(all_ref, length(all_vm))
    response <- m_dynamic_response(all_vm, all_ref_m, test_axis_fsr_g)
    pred_all <- response$predicted_vm_g
    composite_error <- response$composite_error
    overall_response_slope <- response$response_slope
    overall_response_intercept <- response$response_intercept
    overall_tbl <- tibble::tibble(
        composite_error = composite_error,
        response_slope = overall_response_slope,
        response_intercept = overall_response_intercept,
        scale_factor_error = overall_response_slope - 1
    )
    plots <- list()
    align_meta <- list()
    if (isTRUE(add_plot) && requireNamespace("ggplot2", quietly = TRUE)) {
        d <- dplyr::arrange(stages_tbl, rpm)
        plots$vm_mean_vs_rpm <- ggplot2::ggplot(d, ggplot2::aes(x = rpm, y = vm_mean)) +
            ggplot2::geom_line() + ggplot2::geom_point() +
            ggplot2::labs(x = "RPM", y = "VM mean (g)", title = "Stage VM mean across RPM") + ggplot2::theme_bw()
        plots$linearity_vs_rpm <- ggplot2::ggplot(d, ggplot2::aes(x = rpm, y = linearity_error_vs_reference)) +
            ggplot2::geom_line() + ggplot2::geom_point() +
            ggplot2::labs(x = "RPM", y = "Linearity error (% test FSR_VM)", title = "Stage linearity error vs reference") + ggplot2::theme_bw()
        plots$test_vs_ref <- ggplot2::ggplot(data.frame(ref = all_ref_m, test = all_vm), ggplot2::aes(x = ref, y = test)) +
            ggplot2::geom_point(alpha = 0.25, size = 0.6) +
            ggplot2::geom_abline(intercept = overall_response_intercept, slope = overall_response_slope) +
            ggplot2::labs(x = "Reference VM (g)", y = "Test VM (g)", title = "Composite response fit: test vs reference") + ggplot2::theme_bw()
        idx <- dm_downsample_idx(length(all_vm), as.integer(comp_plot_max_n))
        df_ce <- data.frame(sample = seq_along(idx), ref = all_ref_m[idx], test = all_vm[idx])
        p_ce <- ggplot2::ggplot(df_ce) +
            ggplot2::geom_segment(ggplot2::aes(x = sample, xend = sample, y = ref, yend = test), linewidth = 0.2, alpha = 0.25) +
            ggplot2::geom_point(ggplot2::aes(x = sample, y = ref), size = 0.6, alpha = 0.5) +
            ggplot2::geom_point(ggplot2::aes(x = sample, y = test), size = 0.6, alpha = 0.5) +
            ggplot2::labs(x = "Sample index", y = "VM (g)", title = "Composite trace: reference vs test VM", subtitle = sprintf("Composite error = %.2f%% of 1/2 FSR; response slope = %.4f", composite_error, overall_response_slope)) +
            ggplot2::theme_bw()
        if (!is.null(comp_plot_ylim) && length(comp_plot_ylim) == 2) p_ce <- p_ce + ggplot2::coord_cartesian(ylim = comp_plot_ylim)
        plots$composite_error_trace <- p_ce
        if (isTRUE(inspect_alignment)) {
            cnt_df <- dplyr::bind_rows(lapply(stage_names, function(nm) tibble::tibble(stage = nm, rpm = dm_parse_rpm(nm), n_test = nrow(test_clips$stages[[nm]]), n_ref = nrow(ref_clips$stages[[nm]]))))
            cnt_df <- dplyr::arrange(cnt_df, rpm)
            plots$stage_sample_counts <- ggplot2::ggplot(cnt_df, ggplot2::aes(x = rpm)) +
                ggplot2::geom_col(ggplot2::aes(y = n_test), alpha = 0.7) +
                ggplot2::geom_point(ggplot2::aes(y = n_ref), size = 2) +
                ggplot2::labs(x = "RPM", y = "Rows", title = "Stage sample counts") + ggplot2::theme_bw()
            if (is.finite(align_hz) && align_hz > 0) {
                full_test <- if (!is.null(test_clips$full)) test_clips$full else dplyr::bind_rows(test_clips$stages)
                full_ref <- if (!is.null(ref_clips$full)) ref_clips$full else dplyr::bind_rows(ref_clips$stages)
                aT <- dm_get_axes(full_test)
                aR <- dm_get_axes(full_ref)
                yT <- dm_pick_signal(aT, align_by)
                yR <- dm_pick_signal(aR, align_by)
                rsT <- dm_resample_to_hz(dm_get_time(full_test), yT, align_hz)
                rsR <- dm_resample_to_hz(dm_get_time(full_ref), yR, align_hz)
                if (length(rsT$y) && length(rsR$y)) {
                    m <- min(length(rsT$y), length(rsR$y))
                    xc <- dm_xcorr_lag_s(rsT$y[1:m], rsR$y[1:m], align_hz, align_max_lag_s)
                    if (!is.null(xc$df)) {
                        plots$xcorr_overall <- ggplot2::ggplot(xc$df, ggplot2::aes(x = lag_s, y = acf)) +
                            ggplot2::geom_line() + ggplot2::labs(x = "Lag (s)", y = "Cross-correlation", title = paste0("Overall xcorr: ", align_by)) + ggplot2::theme_bw()
                        align_meta$xcorr <- list(align_by = align_by, align_hz = align_hz, align_max_lag_s = align_max_lag_s, estimated_lag_s = xc$lag_s)
                    }
                }
            }
        }
    }
    meta <- list(
        fsr = list(test_axis_fsr_g = test_axis_fsr_g, ref_axis_fsr_g = ref_axis_fsr_g, test_fsr_vm_g = fsr_vm_test_g, ref_fsr_vm_g = fsr_vm_ref_g, half_test_fsr_vm_g = half_fsr_vm_test_g),
        range_source = list(test = test_range_source, reference = ref_range_source),
        comparison_plot_ylim = comp_plot_ylim,
        pairing = "evenly_spaced_sample_index",
        window_s = window_s,
        epoch_time = epoch_time,
        entropy = list(enabled = compute_entropy, m = entropy_m, r = entropy_r, tau = entropy_tau),
        stage_names = stage_names,
        alignment = align_meta
    )
    list(stages = stages_tbl, overall = overall_tbl, plots = plots, meta = meta)
}
