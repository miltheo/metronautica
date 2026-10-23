# Published and modified activity counts.
# Algorithm: Neishabouri et al. (2022).
# Published numerical coefficients: ActiGraph/agcounts, commit
# 3137c9b9a26539ae2d9645d396586fe15faece59 (GPL-3.0).
# Independent R implementation.
# See counts validation documentation.
# Coefficients: ActiGraph (GPL-3.0).

# Published filter coefficients ----
m_ag_reference_filter <- function() list(b = c(-0.009341062898525, -0.02547028965936, -0.004235264826105,
    0.04415241545642, 0.03649371834776, -0.01189396193474, -0.02291739062315, -0.00678816386231, 0),
    a = c(1, -3.63367395910957, 5.03689812757486, -3.09612247819666, 0.50620507633883, 0.32421701566682,
        -0.15685485875559, 0.0194913020589, 0))

# Initialise constant-input filter history.
# Use causal filtering.
m_ag_filter <- function(x, b, a, steady = TRUE) {
    initial_x <- if (steady)
        x[1L] else 0
    initial_y <- if (steady)
        sum(b)/sum(a) * initial_x else 0
    as.numeric(signal::filter(b, a, x, init = rep(initial_y, length(a) - 1L), init.x = rep(initial_x,
        length(b) - 1L)))
}

# Published power-of-two FIR coefficients ----
m_ag_pow2_kernel <- c(-1e-06, -2e-06, -4e-06, -5e-06, -6e-06, -6e-06, -4e-06, 0, 5e-06, 1.1e-05, 1.7e-05,
    2.2e-05, 2.3e-05, 2e-05, 1.3e-05, -0, -1.6e-05, -3.3e-05, -4.9e-05, -5.9e-05, -6.1e-05, -5.2e-05,
    -3.1e-05, -0, 3.8e-05, 7.7e-05, 0.000111, 0.000132, 0.000133, 0.000112, 6.6e-05, -0, -7.8e-05, -0.000156,
    -0.000222, -0.00026, -0.000259, -0.000214, -0.000125, 0, 0.000145, 0.000288, 0.000404, 0.000469,
    0.000464, 0.00038, 0.00022, -0, -0.00025, -0.000493, -0.000687, -0.000791, -0.000777, -0.000632,
    -0.000363, 0, 0.000409, 0.000801, 0.001108, 0.001269, 0.00124, 0.001003, 0.000574, -0, -0.000639,
    -0.001246, -0.001715, -0.001956, -0.001903, -0.001534, -0.000873, 0, 0.000966, 0.001875, 0.002574,
    0.002926, 0.002839, 0.00228, 0.001295, -0, -0.001425, -0.002762, -0.003783, -0.004293, -0.004158,
    -0.003335, -0.001892, 0, 0.002078, 0.004025, 0.005513, 0.006257, 0.006061, 0.004866, 0.002763, -0,
    -0.003045, -0.005909, -0.008115, -0.009237, -0.008981, -0.00724, -0.004131, 0, 0.004606, 0.009005,
    0.012468, 0.014325, 0.014075, 0.011483, 0.006641, -0, -0.007655, -0.015271, -0.02164, -0.025543,
    -0.0259, -0.021926, -0.01325, 0, 0.01718, 0.037161, 0.058432, 0.079245, 0.097796, 0.112422, 0.12178,
    0.125, 0.12178, 0.112422, 0.097796, 0.079245, 0.058432, 0.037161, 0.01718, 0, -0.01325, -0.021926,
    -0.0259, -0.025543, -0.02164, -0.015271, -0.007655, -0, 0.006641, 0.011483, 0.014075, 0.014325, 0.012468,
    0.009005, 0.004606, 0, -0.004131, -0.00724, -0.008981, -0.009237, -0.008115, -0.005909, -0.003045,
    -0, 0.002763, 0.004866, 0.006061, 0.006257, 0.005513, 0.004025, 0.002078, 0, -0.001892, -0.003335,
    -0.004158, -0.004293, -0.003783, -0.002762, -0.001425, -0, 0.001295, 0.00228, 0.002839, 0.002926,
    0.002574, 0.001875, 0.000966, 0, -0.000873, -0.001534, -0.001903, -0.001956, -0.001715, -0.001246,
    -0.000639, -0, 0.000574, 0.001003, 0.00124, 0.001269, 0.001108, 0.000801, 0.000409, 0, -0.000363,
    -0.000632, -0.000777, -0.000791, -0.000687, -0.000493, -0.00025, -0, 0.00022, 0.00038, 0.000464,
    0.000469, 0.000404, 0.000288, 0.000145, 0, -0.000125, -0.000214, -0.000259, -0.00026, -0.000222,
    -0.000156, -7.8e-05, -0, 6.6e-05, 0.000112, 0.000133, 0.000132, 0.000111, 7.7e-05, 3.8e-05, -0, -3.1e-05,
    -5.2e-05, -6.1e-05, -5.9e-05, -4.9e-05, -3.3e-05, -1.6e-05, -0, 1.3e-05, 2e-05, 2.3e-05, 2.2e-05,
    1.7e-05, 1.1e-05, 5e-06, 0, -4e-06, -6e-06, -6e-06, -5e-06, -4e-06, -2e-06, -1e-06)

# Preserve published rate-conversion paths ----
m_ag_resample30 <- function(raw, fs) {
    if (fs %in% c(32, 64, 128, 256)) {
        factor <- 256/fs
        u <- matrix(0, nrow(raw) * factor, 3)
        u[seq.int(1L, nrow(u), by = factor), ] <- raw * factor
        if (fs != 256) {
            # Centred, zero-padded FIR convolution.
            offset <- (length(m_ag_pow2_kernel) - 1L)/2L
            for (j in 1:3) {
                nfft <- stats::nextn(nrow(u) + length(m_ag_pow2_kernel) - 1L)
                z <- Re(fft(fft(c(u[, j], rep(0, nfft - nrow(u)))) * fft(c(m_ag_pow2_kernel, rep(0, nfft -
                  length(m_ag_pow2_kernel)))), inverse = TRUE))/nfft
                u[, j] <- z[seq.int(offset + 1L, length.out = nrow(u))]
            }
        }
        decay <- 1 - 0.307990357416655
        for (j in 1:3) {
            # Use published initial-state scaling.
            # x = .307990357416655*u/decay.
            x <- 0.307990357416655 * u[, j]/decay
            u[, j] <- m_ag_filter(x, decay, c(1, -decay))
        }
        n <- floor(nrow(u) * 30/256)
        y <- matrix(0, n, 3)
        if (n > 1L) {
            target <- (256/30) * seq_len(n - 1L)
            index <- floor(target)
            fraction <- target - index
            for (j in 1:3) y[seq_len(n - 1L), j] <- u[index, j] + fraction * (u[index + 1L, j] - u[index,
                j])
        }
        # Preserve published final zero row.
        return(round(y, 3))
    }
    supported <- c(30, 40, 50, 60, 70, 80, 90, 100)
    if (!fs %in% supported)
        stop("Unsupported count sampling frequency.")
    factors <- c(1, 3, 3, 1, 3, 3, 1, 3)
    down <- c(1, 4, 5, 2, 7, 8, 3, 10)[match(fs, supported)]
    factor <- factors[match(fs, supported)]
    u <- matrix(0, nrow(raw) * factor, 3)
    u[seq.int(1L, nrow(u), by = factor), ] <- raw
    if (!fs %in% c(30, 60, 90)) {
        gain <- pi/(pi + 2 * factor) * factor
        pole <- (pi - 2 * factor)/(pi + 2 * factor)
        for (j in 1:3) u[, j] <- m_ag_filter(u[, j], c(gain, gain), c(1, pole), FALSE)
    }
    round(u[seq.int(1L, nrow(u), by = down), , drop = FALSE], 3)
}

# Standalone count computation.
# Excluded from summary selectors.

# Standalone activity-count calculation ----

# Accumulate axis counts ----
accel_metric_agcounts <- function(tbl, epoch_s = 1, fs_hz, lower_hz = NULL, upper_hz = NULL, filter_order = 4,
    lfe = FALSE, gap_policy = c("error", "zero", "carry_forward"), vm_round = TRUE, start_time = NULL,
    end_time = NULL, boundary = c("error", "pad"), pad_value = NULL, filter_guard_s = 60) {
    tbl <- qc_input_data(tbl)
    meta <- attr(tbl, "meta")
    gap_policy <- match.arg(gap_policy)
    boundary <- match.arg(boundary)
    positive <- function(z) is.numeric(z) && length(z) == 1L && is.finite(z) && z > 0
    if (!positive(epoch_s) || epoch_s != round(epoch_s))
        stop("epoch_s must be a positive integer.")
    if (!positive(fs_hz) || !fs_hz %in% c(30, 40, 50, 60, 70, 80, 90, 100, 32, 64, 128, 256))
        stop("fs_hz must be a supported nominal count sampling frequency.")
    if (!is.logical(lfe) || length(lfe) != 1L || is.na(lfe))
        stop("lfe must be TRUE or FALSE.")
    if (!is.logical(vm_round) || length(vm_round) != 1L || is.na(vm_round))
        stop("vm_round must be TRUE or FALSE.")
    if (!is.numeric(filter_guard_s) || length(filter_guard_s) != 1L || !is.finite(filter_guard_s) ||
        filter_guard_s < 0)
        stop("filter_guard_s must be one finite non-negative duration.")
    if (nrow(tbl) < fs_hz * epoch_s)
        stop("Not enough input for one complete epoch.")
    t <- as.numeric(tbl$time)
    if (any(!is.finite(t)) || any(diff(t) <= 0))
        stop("Count timestamps must be finite and strictly increasing.")
    for (z in list(start_time, end_time)) if (!is.null(z) && (!inherits(z, "POSIXct") || length(z) !=
        1L || !is.finite(as.numeric(z))))
        stop("start_time and end_time must be single finite POSIXct values or NULL.")

    # Resolve requested epoch boundaries ----
    origin <- if (is.null(start_time))
        t[1] else as.numeric(start_time)
    finish <- if (is.null(end_time))
        tail(t, 1) + 1/fs_hz else as.numeric(end_time)
    if (finish <= origin)
        stop("end_time must follow start_time.")
    exact_length <- (finish - origin) * fs_hz
    if (abs(exact_length - round(exact_length)) > 0.05 || exact_length > .Machine$integer.max)
        stop("Requested interval must follow the nominal sample grid and fit R's vector limit.")
    size <- as.integer(round(exact_length))
    discarded <- size%%as.integer(fs_hz * epoch_s)
    size <- size - discarded
    if (size < fs_hz * epoch_s)
        stop("Requested interval contains no complete epoch.")
    finish <- origin + size/fs_hz
    keep <- t >= origin - 1e-07 & t < finish - 1e-07
    if (!any(keep))
        stop("Requested interval has no observed samples.")

    # Validate observed acceleration samples ----
    raw_observed <- as.matrix(tbl[keep, c("ax_g", "ay_g", "az_g")])
    if (any(!is.finite(raw_observed)))
        stop("Acceleration must be finite; NA/Inf values are not inferred timestamp gaps.")
    index <- round((t[keep] - origin) * fs_hz) + 1L
    if (any(abs((t[keep] - origin) * fs_hz - (index - 1)) > 0.05) || anyDuplicated(index))
        stop("Timestamps must occupy unique positions on the supplied nominal sampling grid.")

    # Resolve gaps and boundary padding ----
    leading <- min(index) - 1L
    trailing <- size - max(index)
    if ((leading > 0 || trailing > 0) && boundary == "error")
        stop("Requested interval extends beyond observed samples; use explicit boundary='pad' and pad_value, or select observed coverage.")
    if (boundary == "pad" && (is.null(pad_value) || !is.numeric(pad_value) || length(pad_value) != 3L ||
        any(!is.finite(pad_value))))
        stop("boundary='pad' requires three finite acceleration values in g as pad_value.")
    if (boundary == "error" && !is.null(pad_value))
        stop("pad_value requires boundary='pad'.")
    mask <- rep(1L, size)
    mask[index] <- 0L
    if (leading > 0)
        mask[seq_len(leading)] <- 2L
    if (trailing > 0)
        mask[seq.int(max(index) + 1L, size)] <- 2L
    missing <- sum(mask == 1L)
    if (missing > 0 && gap_policy == "error")
        stop("Recording has sample gaps; select a continuous interval or choose gap_policy explicitly.")

    # Construct nominal sampling grid ----
    raw <- matrix(0, size, 3)
    if (gap_policy == "carry_forward")
        raw <- raw_observed[pmax(1L, findInterval(seq_len(size), index)), , drop = FALSE]
    raw[index, ] <- raw_observed
    padded <- which(mask == 2L)
    if (length(padded))
        raw[padded, ] <- rep(pad_value, each = length(padded))
    runs <- rle(mask == 1L)
    ends <- cumsum(runs$lengths)
    starts <- ends - runs$lengths + 1L
    g <- which(runs$values)
    gap_table <- data.frame(start = as.POSIXct(origin + (starts[g] - 1)/fs_hz, origin = "1970-01-01",
        tz = "UTC"), end = as.POSIXct(origin + ends[g]/fs_hz, origin = "1970-01-01", tz = "UTC"), samples = runs$lengths[g],
        duration_s = runs$lengths[g]/fs_hz)
    reference <- m_ag_reference_filter()

    # Select published or custom filter ----
    custom <- !is.null(lower_hz) || !is.null(upper_hz)
    if (custom) {
        if (!positive(lower_hz) || !positive(upper_hz) || lower_hz >= upper_hz || upper_hz >= 15 || upper_hz >=
            fs_hz/2)
            stop("Supply both cutoffs with 0 < lower_hz < upper_hz < min(15, fs_hz/2).")
        if (!positive(filter_order) || filter_order != round(filter_order) || filter_order > 8)
            stop("filter_order must be an integer from 1 to 8.")
        f <- signal::butter(filter_order, c(lower_hz, upper_hz)/15, type = "pass")
        # Match published peak gain.
        # Retain subsequent count operations.
        w <- seq(0, pi, length.out = 16385)
        response <- function(b, a) {
            top <- vapply(w, function(z) sum(b * exp(-1i * z * (seq_along(b) - 1))), complex(1))
            bot <- vapply(w, function(z) sum(a * exp(-1i * z * (seq_along(a) - 1))), complex(1))
            max(Mod(top/bot), na.rm = TRUE)
        }
        f$b <- f$b * response(reference$b, reference$a)/response(f$b, f$a)
        if (any(!is.finite(c(f$b, f$a))) || any(Mod(polyroot(rev(f$a))) >= 1))
            stop("Requested custom filter is not numerically stable in this implementation; change cutoffs or order.")
        filter <- list(b = f$b, a = f$a)
    } else filter <- reference

    # Convert to published processing rate ----
    y <- m_ag_resample30(raw, fs_hz)
    gain <- (3/4096)/(2.6/256) * 237.5
    for (j in 1:3) y[, j] <- abs(m_ag_filter(y[, j], filter$b, filter$a)) * gain
    if (lfe) {
        small <- y >= 1 & y < 4
        y[y < 1] <- 0
        y <- floor(pmin(y, 128))
        y[small] <- y[small] - 1
    } else {
        y[y < 4] <- 0
        y <- floor(pmin(y, 128))
    }
    groups <- floor(nrow(y)/3)
    ten <- matrix(0, groups, 3)
    for (j in 1:3) ten[, j] <- floor(colSums(matrix(y[seq_len(groups * 3), j], nrow = 3))/3)
    n <- floor(groups/(epoch_s * 10))
    axes <- matrix(0, n, 3)
    for (j in 1:3) axes[, j] <- colSums(matrix(ten[seq_len(n * epoch_s * 10), j], nrow = epoch_s * 10))
    vm <- sqrt(rowSums(axes^2))
    if (vm_round)
        vm <- round(vm)
    result <- tibble::tibble(time = as.POSIXct(origin + (seq_len(n) - 1) * epoch_s, origin = "1970-01-01",
        tz = "UTC"), Axis1 = axes[, 2], Axis2 = axes[, 1], Axis3 = axes[, 3], Vector.Magnitude = vm,
        value = vm)
    attr(result, "settings") <- list(status = "experimental", algorithm = if (custom) "modified_actigraph_counts" else "published_actigraph_counts",
        reference = "Neishabouri et al. (2022), doi:10.1038/s41598-022-16003-x", reference_commit = "3137c9b9a26539ae2d9645d396586fe15faece59",
        filter = if (custom) "causal_butterworth_peak_gain_matched" else "published_exact_coefficients",
        lower_hz = lower_hz, upper_hz = upper_hz, filter_order = if (custom) filter_order else 7L, coefficients = filter,
        filter_application = "causal, constant-input steady-state initialisation", historical_scaling_gain = gain,
        custom_gain_convention = if (custom) "peak matched to historical filter" else "historical coefficients unchanged",
        input_precision = "provided acceleration values; no precision recovery", internal_rounding_decimals = 3L,
        fs_hz = fs_hz, internal_fs_hz = 30, epoch_s = epoch_s, lfe = lfe, missing_samples = missing,
        gap_policy = gap_policy, start_time = as.POSIXct(origin, origin = "1970-01-01", tz = "UTC"),
        end_time = as.POSIXct(finish, origin = "1970-01-01", tz = "UTC"), requested_start_time = start_time,
        requested_end_time = end_time, boundary = boundary, pad_value = pad_value, padded_samples = sum(mask ==
            2L), discarded_trailing_samples = discarded, filter_guard_s = filter_guard_s, precision = meta$processing$precision,
        native_recording_start = meta$acquisition$recording_start_utc, first_observed_sample = tbl$time[1],
        last_observed_sample = tail(tbl$time, 1), gaps = gap_table, trailing_partial_epoch = "discard incomplete raw epochs before rate conversion",
        vm_round = vm_round, axis_mapping = c(Axis1 = "ay_g", Axis2 = "ax_g", Axis3 = "az_g"), custom_threshold_compatibility = if (custom) "not established" else "subject to validation")
    samples_per_epoch <- as.integer(fs_hz * epoch_s)
    epoch_count <- function(which_mask) as.integer(colSums(matrix(which_mask[seq_len(n * samples_per_epoch)],
        nrow = samples_per_epoch)))
    result$input_samples <- epoch_count(mask == 0L)
    result$missing_samples <- epoch_count(mask == 1L)
    result$padded_samples <- epoch_count(mask == 2L)
    result$imputed <- result$missing_samples + result$padded_samples > 0L
    affected <- rep(FALSE, n)
    runs <- rle(mask != 0L)
    ends <- cumsum(runs$lengths)
    starts <- ends - runs$lengths + 1L
    before <- if (fs_hz %in% c(32, 64, 128, 256))
        1 else 0
    for (k in which(runs$values)) {
        lo <- max(1L, floor(((starts[k] - 1)/fs_hz - before)/epoch_s) + 1L)
        hi <- min(n, ceiling((ends[k]/fs_hz + filter_guard_s)/epoch_s))
        if (lo <= hi)
            affected[seq.int(lo, hi)] <- TRUE
    }
    result$affected_by_imputation <- affected
    boundary_flag <- (seq_len(n) - 1) * epoch_s < filter_guard_s
    if (before > 0)
        boundary_flag <- boundary_flag | seq_len(n) * epoch_s > n * epoch_s - before
    result$boundary_affected <- boundary_flag
    settings <- attr(result, "settings")
    settings$filter_guard_before_s <- before
    settings$quality_flags <- "processing-context flags, not a measurement uncertainty bound"
    settings$input_unit <- "g"
    settings$output_unit <- "counts per epoch"
    attr(result, "settings") <- settings
    result
}
