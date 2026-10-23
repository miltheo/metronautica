\name{accel_metric_odba}
\alias{accel_metric_odba}
\title{Compute dynamic body acceleration}
\description{\if{latex}{\out{\sloppy}} Epoch means of overall, vectorial or partial dynamic body acceleration.}
\usage{
accel_metric_odba(tbl, epoch_s, fs_hz, anchor = "center", output =
    c("ODBA", "VEDBA", "PDBA"), static_dynamic_method =
    c("centered_running_mean", "low_pass_static_filter",
    "high_pass_dynamic_filter"), stroke_window_rule = c("fixed_3s",
    "custom_window_s", "stroke_period_1x", "stroke_period_2x",
    "sensitivity_windows"), running_mean_window_s = 3,
    stroke_period_s = NA_real_, lowpass_cutoff_hz = 0.2,
    highpass_cutoff_hz = 0.2, filter_type = "butterworth",
    filter_order = 4, pdba_axes = c("x", "y"), out_unit = c("mg",
    "g"), edge_handling = "partial_centered_window",
    missing_data_policy = "mean_na_rm")
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{output}{\if{latex}{\out{\sloppy}} ODBA sums absolute dynamic components across all three axes; VEDBA uses their Euclidean norm; PDBA sums the selected absolute components. Each is averaged within the output epoch.}
\item{static_dynamic_method}{\if{latex}{\out{\sloppy}} Axis separation method. centered_running_mean subtracts the centred local axis mean; low_pass_static_filter subtracts a low-pass axis estimate; high_pass_dynamic_filter uses high-pass-filtered axes directly.}
\item{stroke_window_rule}{\if{latex}{\out{\sloppy}} Window selection for running-mean separation. fixed_3s uses three seconds; custom_window_s uses running_mean_window_s; stroke_period_1x/2x use max(3, stroke_period_s) or max(3, 2*stroke_period_s). sensitivity_windows uses the requested main window and permits a separate sensitivity summary.}
\item{running_mean_window_s}{\if{latex}{\out{\sloppy}} Requested centred averaging-window duration in seconds. Used by custom_window_s and the main result of sensitivity_windows; fixed_3s overrides it. Rounded to samples using fs_hz.}
\item{stroke_period_s}{\if{latex}{\out{\sloppy}} Positive representative stroke/movement-cycle period in seconds, required for stroke_period_1x/2x. The function does not estimate a movement period.}
\item{lowpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Low-pass cutoff in Hz when static_dynamic_method is low_pass_static_filter. Filter each axis and subtract that static estimate before forming the feature.}
\item{highpass_cutoff_hz}{\if{latex}{\out{\sloppy}} High-pass cutoff in Hz when static_dynamic_method is high_pass_dynamic_filter. The filtered axes are the dynamic components.}
\item{filter_type}{\if{latex}{\out{\sloppy}} Implementation identifier: butterworth is supported for low-/high-pass separation. This is not an automatic choice among filter families.}
\item{filter_order}{\if{latex}{\out{\sloppy}} Order passed to signal::butter for the forward/reverse separation filter. The double-pass frequency response differs from a single pass.}
\item{pdba_axes}{\if{latex}{\out{\sloppy}} PDBA axes: x, y and/or z; default x/y sums their absolute dynamic components. ODBA/VEDBA are unaffected.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output unit: \eqn{g}, or m\eqn{g} (result multiplied by 1000).}
\item{edge_handling}{\if{latex}{\out{\sloppy}} Supported rule partial_centered_window: near signal boundaries, average only the available samples within the centred running window; no external padding is added.}
\item{missing_data_policy}{\if{latex}{\out{\sloppy}} Supported rule mean_na_rm: ignore missing observations when calculating local means and epoch means; all-missing estimates remain undefined. This is not gap repair.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected epoch label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (selected \eqn{g} or m\eqn{g} unit).}

\details{\if{latex}{\out{\sloppy}} Separate static/dynamic axes by the selected implemented method, form ODBA, VEDBA or PDBA, then average within epochs. The centred-window method uses partial available windows at boundaries. A different separation window/filter defines a different pipeline.}
\seealso{\code{\link{compute_accel_summaries}}}

\section{Output settings}{\if{latex}{\out{\sloppy}}
The \code{odba_settings} attribute records the selected metric, separation method, requested/resolved window duration, cycle-period rule, filter settings, selected axes, output unit and missing-data/edge policies. The direct helper returns one selected metric, not a list of multiple features. The summary function provides separately requested ODBA, VEDBA and PDBA columns.
}
