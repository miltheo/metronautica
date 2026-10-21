# Butterworth filtering with forward/reverse cutoff compensation.
mj_filt <- function(data, hz, forder, cutoff, ftype = "low") {
    adjusted_cutoff <- cutoff / (sqrt(2) - 1)^(0.5 / forder)
    wn <- 2 * adjusted_cutoff / hz
    if (any(!is.finite(wn)) || any(wn <= 0 | wn >= 1)) {
        stop("Compensated cutoff must lie strictly below Nyquist and above zero")
    }
    signal::filtfilt(signal::butter(forder, wn, type = ftype, plane = "z"), data)
}

filter_accel_tbl <- function(x, cutoff, forder = 4, ftype = "low") {
    original <- x
    x <- qc_input_data(x)
    stopifnot(is.data.frame(x))
    meta <- accel_meta(x)
    hz <- meta$acquisition$fs_derived_hz
    if (length(hz) != 1L || !is.finite(hz) || hz <= 0) stop("Invalid sampling rate")
    y <- x
    for (axis in c("ax_g", "ay_g", "az_g")) {
        y[[axis]] <- mj_filt(x[[axis]], hz, forder, cutoff, ftype)
    }
    # Append history; input QC no longer describes the filtered samples.
    if (is.null(meta$processing)) meta$processing <- list()
    event <- list(operation = "butterworth_filtfilt", engine_version = "0.0.5",
                  cutoff_hz = cutoff, order = forder, type = ftype,
                  fs_hz = hz, cutoff_compensation = "double-pass")
    meta$processing$history <- c(meta$processing$history, list(event))
    attr(y, "meta") <- meta
    qc_restore_input(original, invalidate_qc(y))
}
