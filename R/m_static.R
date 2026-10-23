# Stationary metrology and diagnostic plots.
# Input: selected stationary acceleration.
# Output: offset, drift, variability, Allan.

static_require <- function() {
    pkgs <- c("dplyr", "tibble", "data.table", "ggplot2", "ggrepel", "scales")
    for (p in pkgs) {
        if (!requireNamespace(p, quietly = TRUE))
            stop("Missing: ", p)
    }
}

# Support standalone sourcing.
`%>%` <- dplyr::`%>%`

.m_static_first_present <- function(...) {
    xs <- list(...)
    for (x in xs) {
        if (is.null(x) || length(x) == 0)
            next
        if (length(x) > 1)
            x <- x[1]
        if (is.character(x)) {
            if (!is.na(x) && nzchar(trimws(x)))
                return(trimws(x))
        }
        else {
            if (!is.na(x))
                return(x)
        }
    }
    NA
}

static_progress_init <- function(progress = TRUE, out_dir = NULL, n_steps = NULL) {
    if (!isTRUE(progress))
        return(NULL)
    if (is.null(n_steps))
        n_steps <- if (is.null(out_dir))
            8
        else 9
    utils::txtProgressBar(min = 0, max = n_steps, style = 3)
}

static_progress_step <- function(pb, i, label = NULL, verbose = FALSE) {
    if (!is.null(pb))
        utils::setTxtProgressBar(pb, i)
    if (isTRUE(verbose) && !is.null(label))
        message(label)
}

static_progress_close <- function(pb) {
    if (!is.null(pb))
        close(pb)
}

static_validate <- function(x) {
    if (!is.data.frame(x))
        stop("x must be an acceleration data table")
    req <- c("time", "ax_g", "ay_g", "az_g")
    if (!all(req %in% names(x)))
        stop("Missing cols: ", paste(setdiff(req, names(x)), collapse = ", "))
    if (!inherits(x$time, "POSIXct"))
        stop("time must be POSIXct")
    attr(x$time, "tzone") <- "UTC"
    invisible(TRUE)
}

static_fs <- function(time_posix) {
    dt <- diff(as.numeric(time_posix))
    dt <- dt[is.finite(dt) & dt > 0]
    if (!length(dt))
        return(NA_real_)
    1/stats::median(dt)
}

# Select stationary assessment interval ----
static_clip <- function(x, start_utc, duration_h) {
    x <- qc_input_data(x)
    static_validate(x)
    if (missing(duration_h) || !is.numeric(duration_h) || length(duration_h) != 1L || !is.finite(duration_h) ||
        duration_h <= 0) {
        stop("Specify a finite positive duration_h for the static assessment.")
    }
    start_utc <- as.POSIXct(start_utc, tz = "UTC")
    if (length(start_utc) != 1L || !is.finite(as.numeric(start_utc)))
        stop("start_utc must specify one valid instant.")
    end_utc <- start_utc + as.difftime(duration_h, units = "hours")
    y <- x[x$time >= start_utc & x$time < end_utc, , drop = FALSE]
    attr(y, "meta") <- attr(x, "meta")
    if (exists("attach_qc", mode = "function")) {
        y <- attach_qc(y, scope = paste("static clip", format(start_utc, tz = "UTC"), "to", format(end_utc,
            tz = "UTC"), "UTC; end exclusive"))
    }
    else {
        m <- attr(y, "meta")
        m$processing$qc <- NULL
        attr(y, "meta") <- m
    }
    m <- accel_meta(y)
    if (is.null(m))
        m <- list()
    if (is.null(m$processing))
        m$processing <- list()

    # Record observed window coverage ----
    times <- y$time[is.finite(as.numeric(y$time))]
    dt <- static_fs(x$time)
    sample_interval_s <- if (is.finite(dt) && dt > 0)
        1/dt
    else 0
    actual_start <- if (length(times))
        min(times)
    else as.POSIXct(NA, tz = "UTC")
    actual_end <- if (length(times))
        max(times)
    else as.POSIXct(NA, tz = "UTC")
    boundary_covered <- length(times) > 0 && as.numeric(actual_start - start_utc, units = "secs") <=
        sample_interval_s * 1.01 && as.numeric(end_utc - actual_end, units = "secs") <= sample_interval_s *
        1.01
    m$processing$static_window <- list(requested_start_utc = start_utc, requested_end_utc = end_utc,
        requested_duration_h = duration_h, first_sample_utc = actual_start, last_sample_utc = actual_end,
        actual_sample_span_h = if (length(times)) as.numeric(actual_end - actual_start, units = "hours") else 0,
        n_samples = nrow(y), requested_boundaries_covered = boundary_covered, internal_continuity_checked = FALSE)
    attr(y, "meta") <- m
    if (!boundary_covered)
        warning("Static recording does not cover both requested window boundaries; inspect processing$static_window and QC.",
            call. = FALSE)
    y
}

# Populated UTC-second means ----
static_1hz_means <- function(x) {
    x <- qc_input_data(x)
    dt <- data.table::as.data.table(x)
    dt[, sec_num := floor(as.numeric(time))]
    dt[, vm := sqrt(ax_g^2 + ay_g^2 + az_g^2)]
    out <- dt[, .(ax_mean = mean(ax_g, na.rm = TRUE), ay_mean = mean(ay_g, na.rm = TRUE), az_mean = mean(az_g,
        na.rm = TRUE), vm_mean = mean(vm, na.rm = TRUE)), by = sec_num]
    data.table::setorder(out, sec_num)
    out[, sec := as.POSIXct(sec_num, origin = "1970-01-01", tz = "UTC")]
    out[, elapsed_h := (sec_num - sec_num[1])/3600]
    out[, sec_num := NULL]
    data.table::setcolorder(out, c("sec", "ax_mean", "ay_mean", "az_mean", "vm_mean", "elapsed_h"))
    tibble::as_tibble(out)
}

# Signed linear drift ----
static_drift <- function(d1) {
    fit_vm <- stats::lm(vm_mean ~ elapsed_h, data = d1)
    fit_ax <- stats::lm(ax_mean ~ elapsed_h, data = d1)
    fit_ay <- stats::lm(ay_mean ~ elapsed_h, data = d1)
    fit_az <- stats::lm(az_mean ~ elapsed_h, data = d1)
    list(vm_drift_g_per_h = unname(stats::coef(fit_vm)[2]), x_drift_g_per_h = unname(stats::coef(fit_ax)[2]),
        y_drift_g_per_h = unname(stats::coef(fit_ay)[2]), z_drift_g_per_h = unname(stats::coef(fit_az)[2]),
        fit_vm = fit_vm)
}

# Initial VM offset bias ----
static_offset_vm_5min <- function(d1) {
    w <- dplyr::filter(d1, elapsed_h <= (5/60))
    mean(w$vm_mean, na.rm = TRUE) - 1
}

static_cv_percent <- function(sd_value, mean_value, min_abs_mean_g = 0.005) {
    if (!is.finite(sd_value) || !is.finite(mean_value))
        return(NA_real_)
    if (abs(mean_value) < min_abs_mean_g)
        return(NA_real_)
    100 * sd_value/abs(mean_value)
}

# Linear-residual standard deviation ----
static_linear_resid_sd <- function(y, elapsed_h) {
    ok <- is.finite(y) & is.finite(elapsed_h)
    y <- y[ok]
    t <- elapsed_h[ok]
    n <- length(y)
    if (n < 3L)
        return(NA_real_)
    yc <- y - mean(y)
    tc <- t - mean(t)
    denom <- sum(tc^2)
    if (!is.finite(denom) || denom <= 0)
        return(stats::sd(y))
    slope <- sum(tc * yc)/denom
    resid <- yc - slope * tc
    sqrt(sum(resid^2)/(n - 2L))
}

static_signal_metrics <- function(v, elapsed_h, prefix, cv_min_abs_mean_g = 0.005, first_window_h = 5/60) {
    ok <- is.finite(v) & is.finite(elapsed_h)
    vv <- v[ok]
    tt <- elapsed_h[ok]
    first <- vv[tt <= first_window_h]
    mean_v <- mean(vv, na.rm = TRUE)
    sd_v <- stats::sd(vv, na.rm = TRUE)
    noise_sd <- static_linear_resid_sd(vv, tt)
    out <- tibble::tibble(n = length(vv), mean_g = mean_v, sd_g = sd_v, detrended_sd_g = noise_sd, sd_5min_g = stats::sd(first,
        na.rm = TRUE), min_g = suppressWarnings(min(vv, na.rm = TRUE)), max_g = suppressWarnings(max(vv,
        na.rm = TRUE)), range_g = suppressWarnings(max(vv, na.rm = TRUE) - min(vv, na.rm = TRUE)), cv_percent = static_cv_percent(sd_v,
        mean_v, cv_min_abs_mean_g), detrended_cv_percent = static_cv_percent(noise_sd, mean_v, cv_min_abs_mean_g))
    names(out) <- paste0(prefix, "_", names(out))
    out
}

# Axis and VM variability ----
static_axis_noise_metrics <- function(x, cv_min_abs_mean_g = 0.005) {
    x <- qc_input_data(x)
    static_validate(x)
    elapsed_h <- as.numeric(difftime(x$time, min(x$time), units = "hours"))
    vm_g <- sqrt(x$ax_g^2 + x$ay_g^2 + x$az_g^2)

    axis_tbl <- dplyr::bind_cols(static_signal_metrics(x$ax_g, elapsed_h, "x", cv_min_abs_mean_g), static_signal_metrics(x$ay_g,
        elapsed_h, "y", cv_min_abs_mean_g), static_signal_metrics(x$az_g, elapsed_h, "z", cv_min_abs_mean_g),
        static_signal_metrics(vm_g, elapsed_h, "vm", cv_min_abs_mean_g))

    raw_sd <- c(X = axis_tbl$x_sd_g, Y = axis_tbl$y_sd_g, Z = axis_tbl$z_sd_g)
    noise_sd <- c(X = axis_tbl$x_detrended_sd_g, Y = axis_tbl$y_detrended_sd_g, Z = axis_tbl$z_detrended_sd_g)
    sd_5min <- c(X = axis_tbl$x_sd_5min_g, Y = axis_tbl$y_sd_5min_g, Z = axis_tbl$z_sd_5min_g)

    dplyr::bind_cols(axis_tbl, tibble::tibble(static_n_samples = nrow(x), max_axis_sd_g = max(raw_sd,
        na.rm = TRUE), max_axis_sd_axis = names(raw_sd)[which.max(raw_sd)], median_axis_sd_g = stats::median(raw_sd,
        na.rm = TRUE), max_axis_noise_sd_g = max(noise_sd, na.rm = TRUE), max_axis_noise_axis = names(noise_sd)[which.max(noise_sd)],
        median_axis_noise_sd_g = stats::median(noise_sd, na.rm = TRUE), max_axis_sd_5min_g = max(sd_5min,
            na.rm = TRUE), max_axis_sd_5min_axis = names(sd_5min)[which.max(sd_5min)], median_axis_sd_5min_g = stats::median(sd_5min,
            na.rm = TRUE), static_noise_floor_mg = max(noise_sd, na.rm = TRUE) * 1000, static_noise_floor_axis = names(noise_sd)[which.max(noise_sd)],
        static_noise_floor_5min_mg = max(sd_5min, na.rm = TRUE) * 1000, static_raw_max_axis_sd_mg = max(raw_sd,
            na.rm = TRUE) * 1000, vm_sd_mg = axis_tbl$vm_sd_g * 1000, vm_noise_sd_mg = axis_tbl$vm_detrended_sd_g *
            1000, vm_sd_5min_mg = axis_tbl$vm_sd_5min_g * 1000, vm_noise_cv_percent = axis_tbl$vm_detrended_cv_percent))
}

# Stationary noise report ----
static_noise_summary_from_tbl <- function(x, instrument = NA_character_, device_id = NA_character_, device_vendor = NA_character_,
    device_model = NA_character_, fs_nominal_hz = NA_real_, fs_derived_hz = NA_real_, out_dir = NULL,
    start_utc, duration_h, verbose = FALSE, progress = TRUE) {

    x <- qc_input_data(x)
    static_require()
    static_validate(x)

    # Write optional output files ----
    if (!is.null(out_dir))
        dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    pb <- static_progress_init(progress = progress, out_dir = out_dir, n_steps = if (is.null(out_dir))
        2
    else 3)
    on.exit(static_progress_close(pb), add = TRUE)

    i <- 0L

    i <- i + 1L
    static_progress_step(pb, i, "[static_noise_summary_from_tbl] clipping window", verbose)

    # Select requested stationary interval ----
    xw <- static_clip(x, start_utc = start_utc, duration_h = duration_h)
    if (nrow(xw) == 0)
        stop("No data remain after clipping")

    i <- i + 1L
    static_progress_step(pb, i, "[static_noise_summary_from_tbl] direct static noise metrics", verbose)

    # Compute raw/detrended variability ----
    noise_metrics <- static_axis_noise_metrics(xw)

    m <- accel_meta(xw)
    id <- as.character(.m_static_first_present(device_id, m$acquisition$device_id))
    vendor <- as.character(.m_static_first_present(device_vendor, m$acquisition$device_vendor))
    model <- .m_static_first_present(device_model, m$acquisition$device_model)
    fs_nom <- .m_static_first_present(fs_nominal_hz, m$acquisition$fs_nominal_hz)
    fs_der <- .m_static_first_present(fs_derived_hz, m$acquisition$fs_derived_hz, static_fs(x$time))
    instrument <- as.character(.m_static_first_present(instrument, trimws(paste(vendor, model))))

    # Assemble metrology outcome summary ----
    summary_tbl <- tibble::tibble(instrument = as.character(instrument), id = as.character(id), trial_duration_h = as.numeric(difftime(max(xw$time),
        min(xw$time), units = "hours")), fs_nominal_hz = fs_nom, fs_derived_hz = fs_der, clip_start_utc = as.character(min(xw$time)),
        clip_end_utc = as.character(max(xw$time))) %>%
        dplyr::bind_cols(noise_metrics)

    files <- NULL
    if (!is.null(out_dir)) {
        i <- i + 1L
        static_progress_step(pb, i, "[static_noise_summary_from_tbl] writing outputs", verbose)

        id_tok <- static_slug(id)
        inst_tok <- static_slug(instrument)
        prefix <- paste0(inst_tok, "__", id_tok)

        f_summary <- file.path(out_dir, paste0(prefix, "__static_noise_summary.csv"))
        f_meta <- file.path(out_dir, paste0(prefix, "__meta.rds"))

        utils::write.csv(summary_tbl, f_summary, row.names = FALSE)
        saveRDS(accel_meta(xw), f_meta)

        files <- list(summary_csv = f_summary, meta_rds = f_meta)
    }

    if (isTRUE(verbose))
        message("[static_noise_summary_from_tbl] done")

    invisible(list(summary = summary_tbl, clipped_data = xw, meta = m, files = files))
}

# Non-overlapping Allan deviation ----
allan_nonoverlap <- function(x, fs_hz, tau_s, min_M = 4L) {
    N <- length(x)
    if (!is.finite(fs_hz) || fs_hz <= 0)
        return(tibble::tibble())
    tau_n <- unique(pmax(1L, as.integer(round(tau_s * fs_hz))))
    out_tau <- numeric(0)
    out_adev <- numeric(0)
    for (n in tau_n) {
        M <- N%/%n
        if (M < min_M)
            next
        X <- matrix(x[seq_len(M * n)], ncol = n, byrow = TRUE)
        seg_means <- rowMeans(X)
        adev <- sqrt(0.5 * mean(diff(seg_means)^2))
        out_tau <- c(out_tau, n/fs_hz)
        out_adev <- c(out_adev, adev)
    }
    tibble::tibble(tau = out_tau, adev = out_adev)
}

# Axis-specific Allan curves ----
static_allan <- function(x) {
    x <- qc_input_data(x)
    fs <- static_fs(x$time)
    tau_s <- 10^seq(log10(0.1), log10(10000), length.out = 60)
    ax <- allan_nonoverlap(x$ax_g, fs, tau_s) %>%
        dplyr::mutate(axis = "X")
    ay <- allan_nonoverlap(x$ay_g, fs, tau_s) %>%
        dplyr::mutate(axis = "Y")
    az <- allan_nonoverlap(x$az_g, fs, tau_s) %>%
        dplyr::mutate(axis = "Z")
    dplyr::bind_rows(ax, ay, az)
}

# Evaluated axis-specific minima ----
static_allan_minima_wide <- function(allan_df) {
    mins <- allan_df %>%
        dplyr::group_by(axis) %>%
        dplyr::slice_min(order_by = adev, n = 1, with_ties = FALSE) %>%
        dplyr::ungroup()
    tibble::tibble(x_cluster_time_s = mins$tau[mins$axis == "X"], y_cluster_time_s = mins$tau[mins$axis ==
        "Y"], z_cluster_time_s = mins$tau[mins$axis == "Z"], x_allan_min_g = mins$adev[mins$axis == "X"],
        y_allan_min_g = mins$adev[mins$axis == "Y"], z_allan_min_g = mins$adev[mins$axis == "Z"])
}

# Drift diagnostic plot ----
plot_static_drift_vm <- function(d1, drift_fit, title_prefix = "Static drift") {
    b0 <- unname(stats::coef(drift_fit)[1])
    b1 <- unname(stats::coef(drift_fit)[2])
    xlab <- max(d1$elapsed_h, na.rm = TRUE)
    ylab <- b0 + b1 * xlab
    lbl <- sprintf("paste(plain(drift), ' = %s ', italic(g), '/h')", formatC(b1, format = "e", digits = 2))
    label_args <- list(geom = "label", x = xlab, y = ylab, label = lbl, parse = TRUE, fill = scales::alpha("white",
        0.7), hjust = 1, vjust = 1, size = 3.6)
    # Use supported annotation arguments.
    # Preserve previous label appearance.
    if (utils::packageVersion("ggplot2") < "4.0.0")
        label_args$label.size <- 0.25
    ggplot2::ggplot(d1, ggplot2::aes(elapsed_h, vm_mean)) +
        ggplot2::geom_line() +
        ggplot2::geom_smooth(method = "lm",
            se = FALSE) + do.call(ggplot2::annotate, label_args) +
        ggplot2::labs(title = title_prefix, x = "Elapsed time (hours)",
            y = expression("VM mean (" * italic(g) * ")")) +
        ggplot2::theme_bw(base_size = 12)
}

# Allan diagnostic plot ----
plot_static_allan <- function(allan_df, title_prefix = "Allan deviation") {
    # Use supported logarithmic tick guides.
    # Preserve tick geometry across versions.
    log_ticks <- if (utils::packageVersion("ggplot2") >= "3.5.0") {
        list(ggplot2::guides(x = ggplot2::guide_axis_logticks(long = 3, mid = 2, short = 1), y = ggplot2::guide_axis_logticks(long = 3,
            mid = 2, short = 1)), ggplot2::theme(axis.ticks.length = grid::unit(-1, "mm")))
    }
    else {
        list(ggplot2::annotation_logticks(sides = "bl"))
    }
    mins <- allan_df %>%
        dplyr::group_by(axis) %>%
        dplyr::slice_min(order_by = adev, n = 1, with_ties = FALSE) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(label = sprintf("atop(paste(tau, ' = %s s'), paste(sigma, ' = %s ', italic(g)))",
            scales::number(tau, accuracy = 0.1, trim = TRUE), scales::scientific(adev, digits = 2)))
    ggplot2::ggplot(allan_df, ggplot2::aes(tau, adev, colour = axis, group = axis)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::geom_point(size = 1.6) +
        ggplot2::geom_point(data = mins, size = 2.6) +
        ggrepel::geom_label_repel(data = mins,
            ggplot2::aes(label = label), parse = TRUE, size = 3.4, label.size = 0.3, label.padding = grid::unit(0.18,
            "lines"), label.r = grid::unit(0.2, "lines"), segment.size = 0.4, max.overlaps = Inf) +
        ggplot2::scale_x_log10() +
        ggplot2::scale_y_log10() +
        ggplot2::labs(title = title_prefix, x = "Cluster time \u03C4 (s)",
            y = expression("Allan deviation (" * italic(g) * ")"), colour = "Axis") +
        ggplot2::theme_bw(base_size = 12) +
        ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) + log_ticks
}

static_slug <- function(x) {
    x <- ifelse(is.na(x) | !nzchar(as.character(x)), "NA", as.character(x))
    x <- gsub("[^A-Za-z0-9]+", "_", x)
    x <- gsub("^_+|_+$", "", x)
    ifelse(nzchar(x), x, "NA")
}

# Combined static metrology report ----
static_metrology_from_tbl <- function(x, instrument = NA_character_, device_id = NA_character_, device_vendor = NA_character_,
    device_model = NA_character_, fs_nominal_hz = NA_real_, fs_derived_hz = NA_real_, out_dir = NULL,
    start_utc, duration_h, title_prefix = NULL, verbose = FALSE, progress = TRUE) {
    x <- qc_input_data(x)

    static_require()
    static_validate(x)

    if (!is.null(out_dir))
        dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    pb <- static_progress_init(progress = progress, out_dir = out_dir)
    on.exit(static_progress_close(pb), add = TRUE)

    i <- 0L

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] clipping window", verbose)
    xw <- static_clip(x, start_utc = start_utc, duration_h = duration_h)
    if (nrow(xw) == 0)
        stop("No data remain after clipping")

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] 1 Hz means", verbose)

    # Compute populated one-second means ----
    d1 <- static_1hz_means(xw)

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] drift", verbose)

    # Fit signed drift slopes ----
    dr <- static_drift(d1)

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] VM offset", verbose)

    # Estimate initial VM offset ----
    off <- static_offset_vm_5min(d1)

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] direct static noise metrics", verbose)
    noise_metrics <- static_axis_noise_metrics(xw)

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] Allan deviation", verbose)

    # Evaluate Allan deviation curves ----
    allan_df <- static_allan(xw)
    if (nrow(allan_df) == 0)
        stop("Allan deviation could not be computed")

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] Allan minima", verbose)
    allan_min <- static_allan_minima_wide(allan_df)

    m <- accel_meta(xw)
    id <- as.character(.m_static_first_present(device_id, m$acquisition$device_id))
    vendor <- as.character(.m_static_first_present(device_vendor, m$acquisition$device_vendor))
    model <- .m_static_first_present(device_model, m$acquisition$device_model)
    fs_nom <- .m_static_first_present(fs_nominal_hz, m$acquisition$fs_nominal_hz)
    fs_der <- .m_static_first_present(fs_derived_hz, m$acquisition$fs_derived_hz, static_fs(x$time))
    instrument <- as.character(.m_static_first_present(instrument, trimws(paste(vendor, model))))

    summary_tbl <- tibble::tibble(instrument = as.character(instrument), id = as.character(id), trial_duration_h = as.numeric(difftime(max(xw$time),
        min(xw$time), units = "hours")), vm_drift_g_per_h = dr$vm_drift_g_per_h, x_drift_g_per_h = dr$x_drift_g_per_h,
        y_drift_g_per_h = dr$y_drift_g_per_h, z_drift_g_per_h = dr$z_drift_g_per_h, vm_offset_g_5min = off,
        fs_nominal_hz = fs_nom, fs_derived_hz = fs_der, clip_start_utc = as.character(min(xw$time)),
        clip_end_utc = as.character(max(xw$time))) %>%
        dplyr::bind_cols(noise_metrics, allan_min)

    if (is.null(title_prefix) || is.na(title_prefix) || !nzchar(title_prefix)) {
        title_prefix <- sprintf("%s | id=%s", instrument, id)
    }

    i <- i + 1L
    static_progress_step(pb, i, "[static_metrology_from_tbl] making plots", verbose)

    # Construct diagnostic figures ----
    p_drift <- plot_static_drift_vm(d1, dr$fit_vm, title_prefix = paste0("Drift | ", title_prefix))
    p_allan <- plot_static_allan(allan_df, title_prefix = paste0("Allan deviation | ", title_prefix))

    files <- NULL
    if (!is.null(out_dir)) {
        i <- i + 1L
        static_progress_step(pb, i, "[static_metrology_from_tbl] writing outputs", verbose)

        id_tok <- static_slug(id)
        inst_tok <- static_slug(instrument)
        prefix <- paste0(inst_tok, "__", id_tok)

        f_summary <- file.path(out_dir, paste0(prefix, "__static_summary.csv"))
        f_allan <- file.path(out_dir, paste0(prefix, "__static_allan.csv"))
        f_drift <- file.path(out_dir, paste0(prefix, "__static_drift.png"))
        f_allanp <- file.path(out_dir, paste0(prefix, "__static_allan.png"))
        f_meta <- file.path(out_dir, paste0(prefix, "__meta.rds"))

        utils::write.csv(summary_tbl, f_summary, row.names = FALSE)
        utils::write.csv(allan_df, f_allan, row.names = FALSE)
        saveRDS(m, f_meta)

        ggplot2::ggsave(f_drift, p_drift, width = 10, height = 5, dpi = 300, units = "in")
        ggplot2::ggsave(f_allanp, p_allan, width = 10, height = 5, dpi = 300, units = "in")

        files <- list(summary_csv = f_summary, allan_csv = f_allan, meta_rds = f_meta, drift_png = f_drift,
            allan_png = f_allanp)
    }

    if (isTRUE(verbose))
        message("[static_metrology_from_tbl] done")

    invisible(list(summary = summary_tbl, allan = allan_df, drift_plot = p_drift, allan_plot = p_allan,
        clipped_data = xw, one_hz = d1, meta = accel_meta(xw), files = files))
}
