# Select intervals with provenance.
# Input: acceleration table or bundle.
# Output: same container type.

is_bundle <- function(obj) {
    is.list(obj) && !is.data.frame(obj) && (is.data.frame(obj$full) || is.data.frame(obj$data))
}

bundle_data <- function(obj) {
    if (is_bundle(obj)) {
        x <- if (is.data.frame(obj$full))
            obj$full
        else obj$data
        if (is.null(attr(x, "meta")) && !is.null(obj$meta))
            attr(x, "meta") <- obj$meta
        return(x)
    }
    obj
}

bundle_meta <- function(obj) {
    if (is_bundle(obj)) {
        meta <- attr(bundle_data(obj), "meta")
        return(if (is.null(meta)) obj$meta else meta)
    }
    attr(obj, "meta")
}

bundle_set_data <- function(obj, x) {
    if (is_bundle(obj)) {
        field <- if (is.data.frame(obj$full))
            "full"
        else "data"
        obj[[field]] <- x
        obj$meta <- attr(x, "meta")
        return(obj)
    }
    x
}

# Processing provenance helpers ----
meta_processing_init <- function(meta) {
    if (is.null(meta$processing) || !is.list(meta$processing))
        meta$processing <- list()
    if (is.null(meta$processing$history) || !is.list(meta$processing$history))
        meta$processing$history <- list()
    meta
}

meta_add_step <- function(meta, step) {
    meta <- meta_processing_init(meta)
    meta$processing$history[[length(meta$processing$history) + 1L]] <- step
    meta
}

# Core clipper ----

# Inclusive interval selection ----
clip_bundle <- function(obj, start_time = NULL, duration_s = NULL, end_time = NULL, trim_pad_s = 0, keep_qc = FALSE) {

    x <- bundle_data(obj)
    meta <- bundle_meta(obj)

    stopifnot(is.data.frame(x), all(c("time", "ax_g", "ay_g", "az_g") %in% names(x)))
    stopifnot(inherits(x$time, "POSIXct"))

    if (!is.null(start_time) && !inherits(start_time, "POSIXct"))
        start_time <- as.POSIXct(start_time, tz = "UTC")
    if (!is.null(end_time) && !inherits(end_time, "POSIXct"))
        end_time <- as.POSIXct(end_time, tz = "UTC")

    if (!is.null(start_time) && is.null(end_time) && is.null(duration_s))
        stop("Provide either duration_s or end_time when start_time is provided.")
    if (is.null(start_time) && is.null(end_time))
        stop("Provide start_time or end_time (with duration_s) for clipping.")

    if (is.null(start_time) && !is.null(end_time) && !is.null(duration_s))
        start_time <- end_time - as.numeric(duration_s)
    if (!is.null(start_time) && is.null(end_time) && !is.null(duration_s))
        end_time <- start_time + as.numeric(duration_s)

    start_time <- start_time - as.numeric(trim_pad_s)
    end_time <- end_time + as.numeric(trim_pad_s)

    t <- x$time
    t_num <- as.numeric(t)
    start_num <- as.numeric(start_time)
    end_num <- as.numeric(end_time)
    if (!is.finite(start_num) || !is.finite(end_num) || end_num < start_num) {
        stop("Clip window is invalid.")
    }

    if (length(t_num) && !anyNA(t_num) && !is.unsorted(t_num, strictly = FALSE)) {
        start_idx <- findInterval(start_num, t_num, left.open = TRUE) + 1L
        end_idx <- findInterval(end_num, t_num)
        start_idx <- max(1L, min(length(t_num) + 1L, start_idx))
        end_idx <- max(0L, min(length(t_num), end_idx))
        if (start_idx > end_idx)
            stop("Clip window returned zero samples.")
        x2 <- x[seq.int(start_idx, end_idx), , drop = FALSE]
    }
    else {
        keep <- (t >= start_time) & (t <= end_time)
        if (!any(keep, na.rm = TRUE))
            stop("Clip window returned zero samples.")
        x2 <- x[keep, , drop = FALSE]
    }

    meta <- meta_processing_init(meta)

    step <- list(step = "clip", clip_start_utc = as.character(format(start_time, tz = "UTC", usetz = TRUE)),
        clip_end_utc = as.character(format(end_time, tz = "UTC", usetz = TRUE)), duration_s = as.numeric(difftime(end_time,
            start_time, units = "secs")), pad_s = as.numeric(trim_pad_s), n_before = nrow(x), n_after = nrow(x2),
        created_utc = as.character(format(Sys.time(), tz = "UTC", usetz = TRUE)))

    meta <- meta_add_step(meta, step)

    if (is.list(meta$acquisition)) {
        meta$acquisition$start_utc <- min(x2$time, na.rm = TRUE)
        meta$acquisition$end_utc <- max(x2$time, na.rm = TRUE)
    }

    # Recompute QC after clipping.

    # Remove inherited interval diagnostics ----
    if (!isTRUE(keep_qc))
        meta$processing$qc <- NULL
    attr(x2, "meta") <- meta

    if (is_bundle(obj)) {
        obj <- bundle_set_data(obj, x2)
        if (!isTRUE(keep_qc))
            obj$qc <- NULL
        return(obj)
    }

    x2
}
