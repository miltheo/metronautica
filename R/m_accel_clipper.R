# =============================================================================
# Clipper module v0.1
# Trim accel_tbl/bundle to a time window and record processing provenance
# Input: acceleration table OR bundle with $data/$full and optional $meta/$qc
# Output: same type, using the original data field and recording clipping in meta$processing$history
# =============================================================================

# ---- Bundle helpers (match parser/QC style) ----------------------------------

is_bundle <- function(obj) {                                                    # detect bundle
    is.list(obj) && !is.data.frame(obj) &&
        (is.data.frame(obj$full) || is.data.frame(obj$data))
}

bundle_data <- function(obj) {                                                  # extract accel_tbl
    if (is_bundle(obj)) {
        x <- if (is.data.frame(obj$full)) obj$full else obj$data
        if (is.null(attr(x, "meta")) && !is.null(obj$meta)) attr(x, "meta") <- obj$meta
        return(x)
    }
    obj                                                                          # accel_tbl
}

bundle_meta <- function(obj) {                                                  # extract meta
    if (is_bundle(obj)) {
        meta <- attr(bundle_data(obj), "meta")
        return(if (is.null(meta)) obj$meta else meta)
    }
    attr(obj, "meta")                                                           # accel_tbl meta attribute
}

bundle_set_data <- function(obj, x) {                                           # set accel_tbl back
    if (is_bundle(obj)) {                                                       # bundle branch
        field <- if (is.data.frame(obj$full)) "full" else "data"
        obj[[field]] <- x                                                       # update data
        obj$meta <- attr(x, "meta")                                              # sync meta
        return(obj)                                                             # return
    }
    x                                                                            # accel_tbl branch
}

# ---- Processing provenance helpers -------------------------------------------

meta_processing_init <- function(meta) {                                        # ensure processing list exists
    if (is.null(meta$processing) || !is.list(meta$processing)) meta$processing <- list()            # init processing
    if (is.null(meta$processing$history) || !is.list(meta$processing$history)) meta$processing$history <- list() # init history
    meta                                                                         # return
}

meta_add_step <- function(meta, step) {                                         # append processing step
    meta <- meta_processing_init(meta)                                          # ensure structure
    meta$processing$history[[length(meta$processing$history) + 1L]] <- step      # append
    meta                                                                         # return
}

# ---- Core clipper ------------------------------------------------------------

clip_bundle <- function(obj,
                        start_time = NULL,                                      # POSIXct start time (UTC tagged)
                        duration_s = NULL,                                      # duration in seconds
                        end_time = NULL,                                        # POSIXct end time (optional alternative)
                        trim_pad_s = 0,                                         # seconds to expand window (+/-)
                        keep_qc = FALSE) {                                      # keep qc? (default drops, re-run QC)

    x <- bundle_data(obj)                                                       # accel_tbl
    meta <- bundle_meta(obj)                                                    # meta

    stopifnot(is.data.frame(x), all(c("time", "ax_g", "ay_g", "az_g") %in% names(x)))
    stopifnot(inherits(x$time, "POSIXct"))                                      # guard

    if (!is.null(start_time) && !inherits(start_time, "POSIXct"))               # coerce start_time
        start_time <- as.POSIXct(start_time, tz = "UTC")                        # to POSIXct
    if (!is.null(end_time) && !inherits(end_time, "POSIXct"))                   # coerce end_time
        end_time <- as.POSIXct(end_time, tz = "UTC")                            # to POSIXct

    if (!is.null(start_time) && is.null(end_time) && is.null(duration_s))       # require end or duration
        stop("Provide either duration_s or end_time when start_time is provided.")
    if (is.null(start_time) && is.null(end_time))                               # require a window
        stop("Provide start_time or end_time (with duration_s) for clipping.")

    if (is.null(start_time) && !is.null(end_time) && !is.null(duration_s))      # back-calc start
        start_time <- end_time - as.numeric(duration_s)
    if (!is.null(start_time) && is.null(end_time) && !is.null(duration_s))      # forward-calc end
        end_time <- start_time + as.numeric(duration_s)

    start_time <- start_time - as.numeric(trim_pad_s)                           # apply pad
    end_time   <- end_time   + as.numeric(trim_pad_s)                           # apply pad

    t <- x$time                                                                 # time vector
    t_num <- as.numeric(t)                                                      # numeric seconds
    start_num <- as.numeric(start_time)                                         # numeric start
    end_num <- as.numeric(end_time)                                             # numeric end
    if (!is.finite(start_num) || !is.finite(end_num) || end_num < start_num) {
        stop("Clip window is invalid.")
    }

    if (length(t_num) && !anyNA(t_num) && !is.unsorted(t_num, strictly = FALSE)) { # fast sorted-time path
        start_idx <- findInterval(start_num, t_num, left.open = TRUE) + 1L       # first time >= start
        end_idx <- findInterval(end_num, t_num)                                  # last time <= end
        start_idx <- max(1L, min(length(t_num) + 1L, start_idx))                 # clamp
        end_idx <- max(0L, min(length(t_num), end_idx))                          # clamp
        if (start_idx > end_idx) stop("Clip window returned zero samples.")      # fail if empty
        x2 <- x[seq.int(start_idx, end_idx), , drop = FALSE]                     # contiguous clip
    } else {                                                                     # fallback for unusual time vectors
        keep <- (t >= start_time) & (t <= end_time)                              # keep mask
        if (!any(keep, na.rm = TRUE)) stop("Clip window returned zero samples.") # fail if empty
        x2 <- x[keep, , drop = FALSE]                                            # clip rows
    }

    meta <- meta_processing_init(meta)                                          # ensure processing list

    step <- list(                                                               # processing record
        step = "clip",                                                          # step name
        clip_start_utc = as.character(format(start_time, tz = "UTC", usetz = TRUE)),
        clip_end_utc   = as.character(format(end_time,   tz = "UTC", usetz = TRUE)),
        duration_s     = as.numeric(difftime(end_time, start_time, units = "secs")),
        pad_s          = as.numeric(trim_pad_s),
        n_before       = nrow(x),
        n_after        = nrow(x2),
        created_utc    = as.character(format(Sys.time(), tz = "UTC", usetz = TRUE))
    )

    meta <- meta_add_step(meta, step)                                           # append to history

    if (is.list(meta$acquisition)) {                                            # update acquisition bounds if present
        meta$acquisition$start_utc <- min(x2$time, na.rm = TRUE)
        meta$acquisition$end_utc   <- max(x2$time, na.rm = TRUE)
    }

    # Whole-recording diagnostics must not masquerade as clip diagnostics.
    if (!isTRUE(keep_qc)) meta$processing$qc <- NULL
    attr(x2, "meta") <- meta                                                    # attach updated meta

    if (is_bundle(obj)) {                                                       # bundle return
        obj <- bundle_set_data(obj, x2)
        if (!isTRUE(keep_qc)) obj$qc <- NULL                                    # drop qc unless requested
        return(obj)
    }

    x2                                                                          # accel_tbl return
}
