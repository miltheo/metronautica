# Canonical post-decode diagnostics. No sorting, repair, filtering or rejection.
# Input adapters are independent of parser sourcing order. Metadata on the
# data is canonical; $meta supplies it when the contained table has none.
qc_input_data <- function(x) {
    validate <- function(data) {
        required <- c("time", "ax_g", "ay_g", "az_g")
        if (!all(required %in% names(data)) || !inherits(data$time, "POSIXct") ||
            !all(vapply(data[c("ax_g", "ay_g", "az_g")], is.numeric, logical(1)))) {
            stop("Acceleration input requires POSIXct time and numeric ax_g, ay_g and az_g in g.", call. = FALSE)
        }
        data
    }
    if (is.data.frame(x)) return(validate(x))
    if (is.list(x)) {
        for (field in c("full", "data")) {
            if (is.data.frame(x[[field]])) {
                data <- x[[field]]
                if (is.null(attr(data, "meta")) && !is.null(x$meta)) {
                    attr(data, "meta") <- x$meta
                }
                return(validate(data))
            }
        }
    }
    stop("Expected an acceleration data table or a bundle containing $data or $full.",
         call. = FALSE)
}

# Return the same container type; keep bundle and table metadata synchronised.
qc_restore_input <- function(original, data, clear_qc = FALSE) {
    if (is.data.frame(original)) return(data)
    field <- if (is.data.frame(original$full)) "full" else "data"
    original[[field]] <- data
    original$meta <- attr(data, "meta")
    if (isTRUE(clear_qc)) original$qc <- NULL
    else if ("qc" %in% names(original)) original$qc <- original$meta$processing$qc
    original
}

qc_number <- function(x, default = NA_real_) {
    if (length(x) != 1L || !is.numeric(x) || !is.finite(x)) default else as.numeric(x)
}

qc_time_intervals <- function(x) {
    x <- qc_input_data(x)
    t <- as.numeric(x$time)
    dt <- diff(t)
    dt[is.finite(dt) & dt > 0]
}

qc_derived_fs <- function(x) {
    dt <- qc_time_intervals(x)
    if (length(dt)) 1 / stats::median(dt) else NA_real_
}

# Five primary post-parse rules; configured full-scale range is a peak-to-peak span.
qc_signal_rules <- function(x, limit = qc_number(attr(x, "meta")$acquisition$full_scale_range_g) / 2) {
    x <- qc_input_data(x)
    stopifnot(is.data.frame(x), inherits(x$time, "POSIXct"),
              identical(names(x), c("time", "ax_g", "ay_g", "az_g")),
              all(vapply(x[-1], is.numeric, logical(1))))
    limit <- qc_number(limit)
    if (is.finite(limit) && limit <= 0) limit <- NA_real_

    t <- as.numeric(x$time); dt <- diff(t)
    pos <- dt[is.finite(dt) & dt>0]
    axes <- x[c('ax_g','ay_g','az_g')]
    valid <- lapply(axes,is.finite)
    eligible <- is.finite(t) & valid[[1]] & valid[[2]] & valid[[3]]
    pair <- if(length(t)>1) eligible[-1] & eligible[-length(t)] & is.finite(dt) & dt>0 else logical()
    pattern <- function(flag) {
        flag[is.na(flag)] <- FALSE
        flag <- flag & valid[[1]] & valid[[2]] & valid[[3]]
        c(samples=sum(flag),sequence=if(length(flag)>1) any(flag[-1] & flag[-length(flag)] & pair) else FALSE)
    }
    zero <- pattern(x$ax_g==0 & x$ay_g==0 & x$az_g==0)
    same <- pattern(x$ax_g==x$ay_g & x$ay_g==x$az_g & x$ax_g!=0)
    finite_n <- vapply(valid,sum,numeric(1))
    zero_n <- vapply(axes,function(a) sum(a==0 & is.finite(a),na.rm=TRUE),numeric(1))
    rail_n <- if(is.finite(limit) && limit>0) sum(vapply(axes,function(a) sum(is.finite(a) & abs(a)>=.98*limit,na.rm=TRUE),numeric(1))) else NA_real_
    data.frame(n_samples=nrow(x),missing_time=sum(!is.finite(t)),
        duplicate_time=sum(duplicated(t[is.finite(t)])),backward_time=sum(is.finite(dt)&dt<0),
        invalid_axis=3*nrow(x)-sum(finite_n),
        median_dt_ms=if(length(pos)) median(pos)*1000 else NA_real_,
        iqr_dt_ms=if(length(pos)>=2) IQR(pos,type=7)*1000 else NA_real_,
        longest_dt_ms=if(length(pos)) max(pos)*1000 else NA_real_,
        zero_x_n=zero_n[1],zero_y_n=zero_n[2],zero_z_n=zero_n[3],
        finite_x_n=finite_n[1],finite_y_n=finite_n[2],finite_z_n=finite_n[3],
        zero_x_pct=if(finite_n[1]) 100*zero_n[1]/finite_n[1] else NA_real_,
        zero_y_pct=if(finite_n[2]) 100*zero_n[2]/finite_n[2] else NA_real_,
        zero_z_pct=if(finite_n[3]) 100*zero_n[3]/finite_n[3] else NA_real_,
        all_zero_samples=unname(zero[1]),all_zero_sequence=as.logical(zero[2]),
        equal_nonzero_samples=unname(same[1]),equal_nonzero_sequence=as.logical(same[2]),
        limit_g=limit,near_limit_fraction=0.98,near_limit_n=rail_n,finite_axis_n=sum(finite_n),
        near_limit_pct=if(sum(finite_n)) 100*rail_n/sum(finite_n) else NA_real_,row.names=NULL)
}

qc_accel_tbl <- function(x) {
    primary <- as.list(qc_signal_rules(x))
    primary$ruleset <- "primary-five"
    primary
}

attach_qc <- function(x, scope = "whole parsed recording") {
    original <- x
    x <- qc_input_data(x)
    m <- attr(x, "meta")
    if (is.null(m)) m <- list()
    m$processing$qc <- qc_accel_tbl(x)
    # Existing acquisition settings also drive analysis filters; QC must not change them.
    if (!is.finite(qc_number(m$acquisition$fs_derived_hz)))
        m$acquisition$fs_derived_hz <- qc_derived_fs(x)
    # Use the existing notes field for scope rather than adding schema structures.
    notes <- m$processing$decode_notes
    if (is.null(notes) || !length(notes) || all(is.na(notes))) notes <- ""
    notes <- unlist(strsplit(paste(notes, collapse = "\n"), "\n", fixed = TRUE))
    notes <- notes[!startsWith(notes, "Canonical QC scope:") & nzchar(notes)]
    m$processing$decode_notes <- paste(c(notes, paste0("Canonical QC scope: ", scope,
        "; ruleset primary-five; no sample removal.")), collapse = "\n")
    attr(x, "meta") <- m
    qc_restore_input(original, x)
}

invalidate_qc <- function(x) {
    original <- x
    x <- qc_input_data(x)
    m <- attr(x, "meta")
    m$processing$qc <- NULL
    if (length(m$processing$decode_notes)) {
        notes <- unlist(strsplit(m$processing$decode_notes, "\n", fixed = TRUE))
        m$processing$decode_notes <- paste(notes[!startsWith(notes, "Canonical QC scope:")], collapse = "\n")
    }
    attr(x, "meta") <- m
    qc_restore_input(original, x, clear_qc = TRUE)
}

# Data-mask column names used by dplyr, data.table and plotting expressions.
# This declares the existing non-standard evaluation to package checking tools;
# it neither creates columns nor changes any calculation.
utils::globalVariables(c(
    ".", ".data", ".trial_key", "acf", "adev", "ai_1s", "ax_g", "axis",
    "ay_g", "az_g", "cv_percent", "device_id", "device_model", "device_vendor",
    "dynamic_range_g", "elapsed_h", "epoch_data", "epoch_id", "error_message",
    "fs_derived_hz", "fs_nominal_hz", "group_label", "id", "label", "lag_s",
    "linearity_error_vs_reference", "mean_value", "mean_var", "metric", "n_epochs",
    "n_ref", "n_test", "pipeline", "pooled_mean", "ref", "row_id", "rpm",
    "sd_value", "sec", "sec_num", "settings", "signal_pipeline", "stage_end_utc",
    "stage_start_utc", "tau", "test", "time", "trial_start_utc", "value",
    "value_to_plot", "vm", "vm_calibration_applied", "vm_mean", "vx", "vy", "vz",
    "was_computed"
))
