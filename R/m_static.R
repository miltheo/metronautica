# ======================================================================
# static_metrology_v3.0.R
# - Uses canonical accel_tbl directly
# - No parsing inside
# - Adds direct static noise, SD, CV, and simple arithmetic metrics
# ======================================================================

static_require <- function() {                                              # Check required namespaces
    pkgs <- c("dplyr","tibble","data.table","ggplot2","ggrepel","scales")   # Package names
    for (p in pkgs) {                                                        # Loop through packages
        if (!requireNamespace(p, quietly = TRUE)) stop("Missing: ", p)       # Stop if missing
    }
}

# Explicit local import also supports source() outside the package loader.
`%>%` <- dplyr::`%>%`

.m_static_first_present <- function(...) {                                             # Return first usable value
    xs <- list(...)                                                           # Collect candidates
    for (x in xs) {                                                           # Check each candidate in order
        if (is.null(x) || length(x) == 0) next                               # Skip NULL and empty
        if (length(x) > 1) x <- x[1]                                         # Use first element if vector
        if (is.character(x)) {                                               # Character handling
            if (!is.na(x) && nzchar(trimws(x))) return(trimws(x))            # Return non-empty string
        } else {                                                              # Non-character handling
            if (!is.na(x)) return(x)                                         # Return first non-missing value
        }
    }
    NA                                                                        # Return missing if nothing usable
}

static_progress_init <- function(progress = TRUE, out_dir = NULL, n_steps = NULL) { # Initialise stage progress bar
    if (!isTRUE(progress)) return(NULL)                                       # Skip if progress disabled
    if (is.null(n_steps)) n_steps <- if (is.null(out_dir)) 8 else 9           # Add file-writing step only when needed
    utils::txtProgressBar(min = 0, max = n_steps, style = 3)                  # Create base progress bar
}

static_progress_step <- function(pb, i, label = NULL, verbose = FALSE) {      # Advance progress bar by one step
    if (!is.null(pb)) utils::setTxtProgressBar(pb, i)                         # Move progress bar
    if (isTRUE(verbose) && !is.null(label)) message(label)                    # Optional stage message
}

static_progress_close <- function(pb) {                                       # Close progress bar safely
    if (!is.null(pb)) close(pb)                                               # Close connection
}

static_validate <- function(x) {                                             # Validate accel_tbl structure
    if (!is.data.frame(x)) stop("x must be an acceleration data table")               # Check class
    req <- c("time","ax_g","ay_g","az_g")                                    # Required columns
    if (!all(req %in% names(x))) stop("Missing cols: ", paste(setdiff(req, names(x)), collapse = ", "))
    if (!inherits(x$time, "POSIXct")) stop("time must be POSIXct")           # Check time type
    attr(x$time, "tzone") <- "UTC"                                           # Enforce UTC
    invisible(TRUE)
}

static_fs <- function(time_posix) {                                          # Estimate sampling frequency
    dt <- diff(as.numeric(time_posix))                                        # Time differences in seconds
    dt <- dt[is.finite(dt) & dt > 0]                                          # Keep valid positive steps
    if (!length(dt)) return(NA_real_)                                         # Return NA if empty
    1 / stats::median(dt)                                                     # Median-based Hz estimate
}

static_clip <- function(x, start_utc, duration_h) {                     # Clip static window
    x <- qc_input_data(x)
    static_validate(x)                                                        # Validate object
    if (missing(duration_h) || !is.numeric(duration_h) || length(duration_h) != 1L || !is.finite(duration_h) || duration_h <= 0) {
        stop("Specify a finite positive duration_h for the static assessment.")
    }
    start_utc <- as.POSIXct(start_utc, tz = "UTC")                            # Parse clip start
    if (length(start_utc) != 1L || !is.finite(as.numeric(start_utc))) stop("start_utc must specify one valid instant.")
    end_utc <- start_utc + as.difftime(duration_h, units = "hours")           # Compute clip end
    y <- x[x$time >= start_utc & x$time < end_utc, , drop = FALSE]            # Subset rows
    attr(y, "meta") <- attr(x, "meta")                                        # Preserve metadata
    if (exists("attach_qc", mode = "function")) {
        y <- attach_qc(y, scope = paste("static clip", format(start_utc, tz = "UTC"),
            "to", format(end_utc, tz = "UTC"), "UTC; end exclusive"))
    } else {
        m <- attr(y, "meta")
        m$processing$qc <- NULL
        attr(y, "meta") <- m
    }
    m <- accel_meta(y)
    if (is.null(m)) m <- list()
    if (is.null(m$processing)) m$processing <- list()
    times <- y$time[is.finite(as.numeric(y$time))]
    dt <- static_fs(x$time)
    sample_interval_s <- if (is.finite(dt) && dt > 0) 1 / dt else 0
    actual_start <- if (length(times)) min(times) else as.POSIXct(NA, tz = "UTC")
    actual_end <- if (length(times)) max(times) else as.POSIXct(NA, tz = "UTC")
    boundary_covered <- length(times) > 0 &&
        as.numeric(actual_start - start_utc, units = "secs") <= sample_interval_s * 1.01 &&
        as.numeric(end_utc - actual_end, units = "secs") <= sample_interval_s * 1.01
    m$processing$static_window <- list(
        requested_start_utc = start_utc, requested_end_utc = end_utc,
        requested_duration_h = duration_h, first_sample_utc = actual_start,
        last_sample_utc = actual_end,
        actual_sample_span_h = if (length(times)) as.numeric(actual_end - actual_start, units = "hours") else 0,
        n_samples = nrow(y), requested_boundaries_covered = boundary_covered,
        internal_continuity_checked = FALSE)
    attr(y, "meta") <- m
    if (!boundary_covered) warning("Static recording does not cover both requested window boundaries; inspect processing$static_window and QC.", call. = FALSE)
    y
}

static_1hz_means <- function(x) {                                             # Compute 1 Hz means
    x <- qc_input_data(x)
    dt <- data.table::as.data.table(x)                                        # Convert to data.table
    dt[, sec_num := floor(as.numeric(time))]                                # Same UTC second bins without text conversion
    dt[, vm := sqrt(ax_g^2 + ay_g^2 + az_g^2)]                                # Vector magnitude
    out <- dt[, .(
        ax_mean = mean(ax_g, na.rm = TRUE),                                   # Mean X per second
        ay_mean = mean(ay_g, na.rm = TRUE),                                   # Mean Y per second
        az_mean = mean(az_g, na.rm = TRUE),                                   # Mean Z per second
        vm_mean = mean(vm,   na.rm = TRUE)                                    # Mean VM per second
    ), by = sec_num]
    data.table::setorder(out, sec_num)
    out[, sec := as.POSIXct(sec_num, origin = "1970-01-01", tz = "UTC")]
    out[, elapsed_h := (sec_num - sec_num[1]) / 3600]
    out[, sec_num := NULL]
    data.table::setcolorder(out, c("sec", "ax_mean", "ay_mean", "az_mean", "vm_mean", "elapsed_h"))
    tibble::as_tibble(out)                                                    # Return tibble
}

static_drift <- function(d1) {                                                # Fit drift models
    fit_vm <- stats::lm(vm_mean ~ elapsed_h, data = d1)                       # VM drift model
    fit_ax <- stats::lm(ax_mean ~ elapsed_h, data = d1)                       # X drift model
    fit_ay <- stats::lm(ay_mean ~ elapsed_h, data = d1)                       # Y drift model
    fit_az <- stats::lm(az_mean ~ elapsed_h, data = d1)                       # Z drift model
    list(
        vm_drift_g_per_h = unname(stats::coef(fit_vm)[2]),                    # VM slope
        x_drift_g_per_h  = unname(stats::coef(fit_ax)[2]),                    # X slope
        y_drift_g_per_h  = unname(stats::coef(fit_ay)[2]),                    # Y slope
        z_drift_g_per_h  = unname(stats::coef(fit_az)[2]),                    # Z slope
        fit_vm = fit_vm                                                        # Keep VM fit for plotting
    )
}

static_offset_vm_5min <- function(d1) {                                       # VM offset in first 5 min
    w <- dplyr::filter(d1, elapsed_h <= (5 / 60))                              # Keep first 5 minutes
    mean(w$vm_mean, na.rm = TRUE) - 1                                          # Deviation from 1 g
}

static_cv_percent <- function(sd_value, mean_value, min_abs_mean_g = 0.005) { # Percent CV with near-zero guard
    if (!is.finite(sd_value) || !is.finite(mean_value)) return(NA_real_)       # Missing guard
    if (abs(mean_value) < min_abs_mean_g) return(NA_real_)                     # Axis near 0 g: CV is not interpretable
    100 * sd_value / abs(mean_value)                                           # Percent CV
}

static_linear_resid_sd <- function(y, elapsed_h) {                            # SD after removing linear trend
    ok <- is.finite(y) & is.finite(elapsed_h)                                  # Valid rows
    y <- y[ok]                                                                 # Keep valid signal
    t <- elapsed_h[ok]                                                         # Keep valid time
    n <- length(y)                                                             # Number of samples
    if (n < 3L) return(NA_real_)                                               # Need at least 3 samples
    yc <- y - mean(y)                                                          # Centre signal
    tc <- t - mean(t)                                                          # Centre time
    denom <- sum(tc^2)                                                         # Time variance numerator
    if (!is.finite(denom) || denom <= 0) return(stats::sd(y))                  # Constant time fallback
    slope <- sum(tc * yc) / denom                                              # Least-squares slope without lm object
    resid <- yc - slope * tc                                                   # Residual about fitted line
    sqrt(sum(resid^2) / (n - 2L))                                               # Residual SD
}

static_signal_metrics <- function(v, elapsed_h, prefix, cv_min_abs_mean_g = 0.005,
                                  first_window_h = 5 / 60) {                  # One-signal arithmetic metrics
    ok <- is.finite(v) & is.finite(elapsed_h)                                  # Valid rows
    vv <- v[ok]                                                                # Signal values
    tt <- elapsed_h[ok]                                                        # Times
    first <- vv[tt <= first_window_h]                                          # First-window values
    mean_v <- mean(vv, na.rm = TRUE)                                           # Mean
    sd_v <- stats::sd(vv, na.rm = TRUE)                                        # Raw SD
    noise_sd <- static_linear_resid_sd(vv, tt)                                 # Detrended SD
    out <- tibble::tibble(
        n = length(vv),
        mean_g = mean_v,
        sd_g = sd_v,
        detrended_sd_g = noise_sd,
        sd_5min_g = stats::sd(first, na.rm = TRUE),
        min_g = suppressWarnings(min(vv, na.rm = TRUE)),
        max_g = suppressWarnings(max(vv, na.rm = TRUE)),
        range_g = suppressWarnings(max(vv, na.rm = TRUE) - min(vv, na.rm = TRUE)),
        cv_percent = static_cv_percent(sd_v, mean_v, cv_min_abs_mean_g),
        detrended_cv_percent = static_cv_percent(noise_sd, mean_v, cv_min_abs_mean_g)
    )
    names(out) <- paste0(prefix, "_", names(out))                              # Prefix output columns
    out
}

static_axis_noise_metrics <- function(x, cv_min_abs_mean_g = 0.005) {         # Direct static SD/noise summary
    x <- qc_input_data(x)
    static_validate(x)                                                        # Validate object
    elapsed_h <- as.numeric(difftime(x$time, min(x$time), units = "hours"))    # Elapsed time in hours
    vm_g <- sqrt(x$ax_g^2 + x$ay_g^2 + x$az_g^2)                               # Vector magnitude

    axis_tbl <- dplyr::bind_cols(
        static_signal_metrics(x$ax_g, elapsed_h, "x", cv_min_abs_mean_g),
        static_signal_metrics(x$ay_g, elapsed_h, "y", cv_min_abs_mean_g),
        static_signal_metrics(x$az_g, elapsed_h, "z", cv_min_abs_mean_g),
        static_signal_metrics(vm_g,  elapsed_h, "vm", cv_min_abs_mean_g)
    )

    raw_sd <- c(X = axis_tbl$x_sd_g, Y = axis_tbl$y_sd_g, Z = axis_tbl$z_sd_g) # Axis raw SD
    noise_sd <- c(X = axis_tbl$x_detrended_sd_g, Y = axis_tbl$y_detrended_sd_g, Z = axis_tbl$z_detrended_sd_g) # Axis detrended SD
    sd_5min <- c(X = axis_tbl$x_sd_5min_g, Y = axis_tbl$y_sd_5min_g, Z = axis_tbl$z_sd_5min_g) # First 5 min SD

    dplyr::bind_cols(
        axis_tbl,
        tibble::tibble(
            static_n_samples = nrow(x),
            max_axis_sd_g = max(raw_sd, na.rm = TRUE),
            max_axis_sd_axis = names(raw_sd)[which.max(raw_sd)],
            median_axis_sd_g = stats::median(raw_sd, na.rm = TRUE),
            max_axis_noise_sd_g = max(noise_sd, na.rm = TRUE),
            max_axis_noise_axis = names(noise_sd)[which.max(noise_sd)],
            median_axis_noise_sd_g = stats::median(noise_sd, na.rm = TRUE),
            max_axis_sd_5min_g = max(sd_5min, na.rm = TRUE),
            max_axis_sd_5min_axis = names(sd_5min)[which.max(sd_5min)],
            median_axis_sd_5min_g = stats::median(sd_5min, na.rm = TRUE),
            static_noise_floor_mg = max(noise_sd, na.rm = TRUE) * 1000,
            static_noise_floor_axis = names(noise_sd)[which.max(noise_sd)],
            static_noise_floor_5min_mg = max(sd_5min, na.rm = TRUE) * 1000,
            static_raw_max_axis_sd_mg = max(raw_sd, na.rm = TRUE) * 1000,
            vm_sd_mg = axis_tbl$vm_sd_g * 1000,
            vm_noise_sd_mg = axis_tbl$vm_detrended_sd_g * 1000,
            vm_sd_5min_mg = axis_tbl$vm_sd_5min_g * 1000,
            vm_noise_cv_percent = axis_tbl$vm_detrended_cv_percent
        )
    )
}

static_noise_summary_from_tbl <- function(x,
                                          instrument = NA_character_,
                                          device_id = NA_character_,
                                          device_vendor = NA_character_,
                                          device_model = NA_character_,
                                          fs_nominal_hz = NA_real_,
                                          fs_derived_hz = NA_real_,
                                          out_dir = NULL,
                                          start_utc,
                                          duration_h,
                                          verbose = FALSE,
                                          progress = TRUE) {

    x <- qc_input_data(x)
    static_require()                                                          # Load packages
    static_validate(x)                                                        # Validate input

    if (!is.null(out_dir)) dir.create(out_dir, showWarnings = FALSE, recursive = TRUE) # Create output dir

    pb <- static_progress_init(
        progress = progress,
        out_dir = out_dir,
        n_steps = if (is.null(out_dir)) 2 else 3
    )                                                                         # Start progress bar
    on.exit(static_progress_close(pb), add = TRUE)                            # Ensure closure on exit

    i <- 0L                                                                   # Stage counter

    i <- i + 1L                                                               # Step 1
    static_progress_step(pb, i, "[static_noise_summary_from_tbl] clipping window", verbose)
    xw <- static_clip(x, start_utc = start_utc, duration_h = duration_h)      # Clip static window
    if (nrow(xw) == 0) stop("No data remain after clipping")                  # Guard empty clip

    i <- i + 1L                                                               # Step 2
    static_progress_step(pb, i, "[static_noise_summary_from_tbl] direct static noise metrics", verbose)
    noise_metrics <- static_axis_noise_metrics(xw)                            # Raw SD, detrended SD, CV, range metrics

    m <- accel_meta(xw)                                                       # Clipped-window metadata
    id <- as.character(.m_static_first_present(device_id, m$acquisition$device_id))     # Resolve device ID
    vendor <- as.character(.m_static_first_present(device_vendor, m$acquisition$device_vendor)) # Resolve vendor
    model <- .m_static_first_present(device_model, m$acquisition$device_model)          # Resolve model
    fs_nom <- .m_static_first_present(fs_nominal_hz, m$acquisition$fs_nominal_hz)       # Resolve nominal fs
    fs_der <- .m_static_first_present(fs_derived_hz, m$acquisition$fs_derived_hz, static_fs(x$time)) # Resolve derived fs
    instrument <- as.character(.m_static_first_present(instrument, trimws(paste(vendor, model)))) # Resolve instrument

    summary_tbl <- tibble::tibble(
        instrument        = as.character(instrument),
        id                = as.character(id),
        trial_duration_h  = as.numeric(difftime(max(xw$time), min(xw$time), units = "hours")),
        fs_nominal_hz     = fs_nom,
        fs_derived_hz     = fs_der,
        clip_start_utc    = as.character(min(xw$time)),
        clip_end_utc      = as.character(max(xw$time))
    ) %>% dplyr::bind_cols(noise_metrics)

    files <- NULL                                                             # Default no files
    if (!is.null(out_dir)) {                                                  # Write outputs if requested
        i <- i + 1L                                                           # Step 3
        static_progress_step(pb, i, "[static_noise_summary_from_tbl] writing outputs", verbose)

        id_tok <- static_slug(id)                                             # Safe ID token
        inst_tok <- static_slug(instrument)                                   # Safe instrument token
        prefix <- paste0(inst_tok, "__", id_tok)                              # File prefix

        f_summary <- file.path(out_dir, paste0(prefix, "__static_noise_summary.csv")) # Summary path
        f_meta <- file.path(out_dir, paste0(prefix, "__meta.rds"))            # Metadata path

        utils::write.csv(summary_tbl, f_summary, row.names = FALSE)           # Write summary CSV
        saveRDS(accel_meta(xw), f_meta)                                        # Metadata for the saved window

        files <- list(summary_csv = f_summary, meta_rds = f_meta)             # Return file paths
    }

    if (isTRUE(verbose)) message("[static_noise_summary_from_tbl] done")      # Final message

    invisible(list(
        summary = summary_tbl,
        clipped_data = xw,
        meta = m,
        files = files
    ))
}

allan_nonoverlap <- function(x, fs_hz, tau_s, min_M = 4L) {                   # Allan deviation
    N <- length(x)                                                             # Signal length
    if (!is.finite(fs_hz) || fs_hz <= 0) return(tibble::tibble())              # Guard invalid fs
    tau_n <- unique(pmax(1L, as.integer(round(tau_s * fs_hz))))                # Convert tau to samples
    out_tau <- numeric(0)                                                      # Store tau
    out_adev <- numeric(0)                                                     # Store adev
    for (n in tau_n) {                                                         # Loop tau values
        M <- N %/% n                                                           # Number of non-overlap segments
        if (M < min_M) next                                                    # Skip too-short tau
        X <- matrix(x[seq_len(M * n)], ncol = n, byrow = TRUE)                 # Reshape into segments
        seg_means <- rowMeans(X)                                               # Segment means
        adev <- sqrt(0.5 * mean(diff(seg_means)^2))                            # Allan deviation
        out_tau  <- c(out_tau,  n / fs_hz)                                     # Store tau in seconds
        out_adev <- c(out_adev, adev)                                          # Store adev
    }
    tibble::tibble(tau = out_tau, adev = out_adev)                             # Return tibble
}

static_allan <- function(x) {                                                  # Allan deviation for X/Y/Z
    x <- qc_input_data(x)
    fs <- static_fs(x$time)                                                    # Estimate Hz
    tau_s <- 10^seq(log10(0.1), log10(10000), length.out = 60)                 # Log tau sequence
    ax <- allan_nonoverlap(x$ax_g, fs, tau_s) %>% dplyr::mutate(axis = "X")    # X axis
    ay <- allan_nonoverlap(x$ay_g, fs, tau_s) %>% dplyr::mutate(axis = "Y")    # Y axis
    az <- allan_nonoverlap(x$az_g, fs, tau_s) %>% dplyr::mutate(axis = "Z")    # Z axis
    dplyr::bind_rows(ax, ay, az)                                               # Combine axes
}

static_allan_minima_wide <- function(allan_df) {                               # Allan minima summary
    mins <- allan_df %>%
        dplyr::group_by(axis) %>%
        dplyr::slice_min(order_by = adev, n = 1, with_ties = FALSE) %>%
        dplyr::ungroup()
    tibble::tibble(
        x_cluster_time_s = mins$tau[mins$axis == "X"],                         # X tau at minimum
        y_cluster_time_s = mins$tau[mins$axis == "Y"],                         # Y tau at minimum
        z_cluster_time_s = mins$tau[mins$axis == "Z"],                         # Z tau at minimum
        x_allan_min_g    = mins$adev[mins$axis == "X"],                        # X minimum adev
        y_allan_min_g    = mins$adev[mins$axis == "Y"],                        # Y minimum adev
        z_allan_min_g    = mins$adev[mins$axis == "Z"]                         # Z minimum adev
    )
}

plot_static_drift_vm <- function(d1, drift_fit, title_prefix = "Static drift") {  # VM drift plot
    b0 <- unname(stats::coef(drift_fit)[1])                                    # Intercept
    b1 <- unname(stats::coef(drift_fit)[2])                                    # Slope
    xlab <- max(d1$elapsed_h, na.rm = TRUE)                                    # X location for label
    ylab <- b0 + b1 * xlab                                                     # Y location for label
    lbl <- sprintf("drift = %s g/h", formatC(b1, format = "e", digits = 2))    # Label text
    label_args <- list(geom = "label", x = xlab, y = ylab, label = lbl,
                       fill = scales::alpha("white", 0.7),
                       hjust = 1, vjust = 1, size = 3.6)
    # ggplot2 >= 4 ignores label.size in annotate(); retain its existing default
    # appearance there, and the original explicit setting on older releases.
    if (utils::packageVersion("ggplot2") < "4.0.0") label_args$label.size <- 0.25
    ggplot2::ggplot(d1, ggplot2::aes(elapsed_h, vm_mean)) +
        ggplot2::geom_line() +
        ggplot2::geom_smooth(method = "lm", se = FALSE) +
        do.call(ggplot2::annotate, label_args) +
        ggplot2::labs(title = title_prefix, x = "Elapsed time (hours)", y = "VM mean (g)") +
        ggplot2::theme_bw(base_size = 12)
}

plot_static_allan <- function(allan_df, title_prefix = "Allan deviation") {    # Allan deviation plot
    # Modern axis guides avoid annotation_logticks() recycling warnings in R-devel.
    # Match the previous inward 1/2/3-mm ticks; retain ggplot2 3.4 compatibility.
    log_ticks <- if (utils::packageVersion("ggplot2") >= "3.5.0") {
        list(ggplot2::guides(
            x = ggplot2::guide_axis_logticks(long = 3, mid = 2, short = 1),
            y = ggplot2::guide_axis_logticks(long = 3, mid = 2, short = 1)),
            ggplot2::theme(axis.ticks.length = grid::unit(-1, "mm")))
    } else {
        list(ggplot2::annotation_logticks(sides = "bl"))
    }
    mins <- allan_df %>%
        dplyr::group_by(axis) %>%
        dplyr::slice_min(order_by = adev, n = 1, with_ties = FALSE) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(label = sprintf("\u03C4 = %s s\n\u03C3 = %s g",
                                      scales::number(tau, accuracy = 0.1, trim = TRUE),
                                      scales::scientific(adev, digits = 2)))
    ggplot2::ggplot(allan_df, ggplot2::aes(tau, adev, colour = axis, group = axis)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::geom_point(size = 1.6) +
        ggplot2::geom_point(data = mins, size = 2.6) +
        ggrepel::geom_label_repel(data = mins, ggplot2::aes(label = label),
                                  size = 3.4, label.size = 0.3,
                                  label.padding = grid::unit(0.18, "lines"),
                                  label.r = grid::unit(0.2, "lines"),
                                  segment.size = 0.4, max.overlaps = Inf) +
        ggplot2::scale_x_log10() +
        ggplot2::scale_y_log10() +
        ggplot2::labs(title = title_prefix, x = "Cluster time \u03C4 (s)", y = "Allan deviation (g)", colour = "Axis") +
        ggplot2::theme_bw(base_size = 12) +
        ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) +
        log_ticks
}

static_slug <- function(x) {                                                   # Make safe filename token
    x <- ifelse(is.na(x) | !nzchar(as.character(x)), "NA", as.character(x))    # Protect missing
    x <- gsub("[^A-Za-z0-9]+", "_", x)                                         # Replace non-alnum
    x <- gsub("^_+|_+$", "", x)                                                # Trim underscores
    ifelse(nzchar(x), x, "NA")                                                 # Protect empty
}

static_metrology_from_tbl <- function(x,
                                      instrument = NA_character_,
                                      device_id = NA_character_,
                                      device_vendor = NA_character_,
                                      device_model = NA_character_,
                                      fs_nominal_hz = NA_real_,
                                      fs_derived_hz = NA_real_,
                                      out_dir = NULL,
                                      start_utc,
                                      duration_h,
                                      title_prefix = NULL,
                                      verbose = FALSE,
                                      progress = TRUE) {
    x <- qc_input_data(x)

    static_require()                                                          # Load packages
    static_validate(x)                                                        # Validate input

    if (!is.null(out_dir)) dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)  # Create output dir

    pb <- static_progress_init(progress = progress, out_dir = out_dir)        # Start progress bar
    on.exit(static_progress_close(pb), add = TRUE)                            # Ensure closure on exit

    i <- 0L                                                                   # Stage counter

    i <- i + 1L                                                               # Step 1
    static_progress_step(pb, i, "[static_metrology_from_tbl] clipping window", verbose)
    xw <- static_clip(x, start_utc = start_utc, duration_h = duration_h)      # Clip static window
    if (nrow(xw) == 0) stop("No data remain after clipping")                  # Guard empty clip

    i <- i + 1L                                                               # Step 2
    static_progress_step(pb, i, "[static_metrology_from_tbl] 1 Hz means", verbose)
    d1 <- static_1hz_means(xw)                                                # 1 Hz summaries

    i <- i + 1L                                                               # Step 3
    static_progress_step(pb, i, "[static_metrology_from_tbl] drift", verbose)
    dr <- static_drift(d1)                                                    # Drift results

    i <- i + 1L                                                               # Step 4
    static_progress_step(pb, i, "[static_metrology_from_tbl] VM offset", verbose)
    off <- static_offset_vm_5min(d1)                                          # 5 min VM offset

    i <- i + 1L                                                               # Step 5
    static_progress_step(pb, i, "[static_metrology_from_tbl] direct static noise metrics", verbose)
    noise_metrics <- static_axis_noise_metrics(xw)                            # Raw SD, detrended SD, CV, range metrics

    i <- i + 1L                                                               # Step 6
    static_progress_step(pb, i, "[static_metrology_from_tbl] Allan deviation", verbose)
    allan_df <- static_allan(xw)                                              # Allan results
    if (nrow(allan_df) == 0) stop("Allan deviation could not be computed")    # Guard empty allan

    i <- i + 1L                                                               # Step 7
    static_progress_step(pb, i, "[static_metrology_from_tbl] Allan minima", verbose)
    allan_min <- static_allan_minima_wide(allan_df)                           # Allan minima row

    m <- accel_meta(xw)                                                       # Clipped-window metadata
    id <- as.character(.m_static_first_present(device_id, m$acquisition$device_id))     # Resolve device ID
    vendor <- as.character(.m_static_first_present(device_vendor, m$acquisition$device_vendor))       # Resolve vendor
    model <- .m_static_first_present(device_model, m$acquisition$device_model)          # Resolve model
    fs_nom <- .m_static_first_present(fs_nominal_hz, m$acquisition$fs_nominal_hz)       # Resolve nominal fs
    fs_der <- .m_static_first_present(fs_derived_hz, m$acquisition$fs_derived_hz, static_fs(x$time))  # Resolve derived fs
    instrument <- as.character(.m_static_first_present(instrument, trimws(paste(vendor, model))))     # Resolve instrument label

    summary_tbl <- tibble::tibble(
        instrument        = as.character(instrument),
        id                = as.character(id),
        trial_duration_h  = as.numeric(difftime(max(xw$time), min(xw$time), units = "hours")),  # Actual clipped duration
        vm_drift_g_per_h  = dr$vm_drift_g_per_h,                              # VM drift
        x_drift_g_per_h   = dr$x_drift_g_per_h,                               # X drift
        y_drift_g_per_h   = dr$y_drift_g_per_h,                               # Y drift
        z_drift_g_per_h   = dr$z_drift_g_per_h,                               # Z drift
        vm_offset_g_5min  = off,                                              # VM offset
        fs_nominal_hz     = fs_nom,                                           # Nominal frequency
        fs_derived_hz     = fs_der,                                           # Derived frequency
        clip_start_utc    = as.character(min(xw$time)),
        clip_end_utc      = as.character(max(xw$time))
    ) %>% dplyr::bind_cols(noise_metrics, allan_min)

    if (is.null(title_prefix) || is.na(title_prefix) || !nzchar(title_prefix)) {  # Default plot title prefix
        title_prefix <- sprintf("%s | id=%s", instrument, id)
    }

    i <- i + 1L                                                               # Step 8
    static_progress_step(pb, i, "[static_metrology_from_tbl] making plots", verbose)
    p_drift <- plot_static_drift_vm(d1, dr$fit_vm, title_prefix = paste0("Drift | ", title_prefix))  # Drift plot
    p_allan <- plot_static_allan(allan_df, title_prefix = paste0("Allan deviation | ", title_prefix)) # Allan plot

    files <- NULL                                                             # Default no files
    if (!is.null(out_dir)) {                                                  # Write outputs if requested
        i <- i + 1L                                                           # Step 9
        static_progress_step(pb, i, "[static_metrology_from_tbl] writing outputs", verbose)

        id_tok <- static_slug(id)                                             # Safe ID token
        inst_tok <- static_slug(instrument)                                   # Safe instrument token
        prefix <- paste0(inst_tok, "__", id_tok)                              # File prefix

        f_summary <- file.path(out_dir, paste0(prefix, "__static_summary.csv")) # Summary path
        f_allan   <- file.path(out_dir, paste0(prefix, "__static_allan.csv"))   # Allan path
        f_drift   <- file.path(out_dir, paste0(prefix, "__static_drift.png"))   # Drift plot path
        f_allanp  <- file.path(out_dir, paste0(prefix, "__static_allan.png"))   # Allan plot path
        f_meta    <- file.path(out_dir, paste0(prefix, "__meta.rds"))            # Metadata object path

        utils::write.csv(summary_tbl, f_summary, row.names = FALSE)           # Write summary CSV
        utils::write.csv(allan_df, f_allan, row.names = FALSE)                # Write Allan CSV
        saveRDS(m, f_meta)                                                    # Save metadata object as RDS

        ggplot2::ggsave(f_drift, p_drift, width = 10, height = 5, dpi = 300, units = "in")   # Save drift plot
        ggplot2::ggsave(f_allanp, p_allan, width = 10, height = 5, dpi = 300, units = "in")   # Save Allan plot

        files <- list(
            summary_csv = f_summary,
            allan_csv   = f_allan,
            meta_rds    = f_meta,
            drift_png   = f_drift,
            allan_png   = f_allanp
        )                                                                      # Return file paths
    }

    if (isTRUE(verbose)) message("[static_metrology_from_tbl] done")          # Final message

    invisible(list(
        summary = summary_tbl,                                                # Summary row
        allan = allan_df,                                                     # Allan full table
        drift_plot = p_drift,                                                 # Drift plot
        allan_plot = p_allan,                                                 # Allan plot
        clipped_data = xw,                                                    # Clipped accel_tbl
        one_hz = d1,                                                          # 1 Hz summary table
        meta = accel_meta(xw),                                                # Metadata for the clipped signal
        files = files                                                         # Output file paths
    ))
}
