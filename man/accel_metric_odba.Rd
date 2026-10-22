\name{accel_metric_odba}
\alias{accel_metric_odba}
\title{Compute dynamic body acceleration}
\description{\if{latex}{\out{\sloppy}} Compute dynamic body acceleration.}
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
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{output}{\if{latex}{\out{\sloppy}} ODBA sums absolute dynamic components across all three axes; VEDBA uses their Euclidean norm; PDBA sums the selected absolute components. Each is averaged within the output epoch.}
\item{static_dynamic_method}{\if{latex}{\out{\sloppy}} Axis separation method. centered_running_mean subtracts the centred local axis mean; low_pass_static_filter subtracts a low-pass axis estimate; high_pass_dynamic_filter uses high-pass-filtered axes directly.}
\item{stroke_window_rule}{\if{latex}{\out{\sloppy}} Window selection for running-mean separation. fixed_3s uses three seconds; custom_window_s uses running_mean_window_s; stroke_period_1x/2x use max(3, stroke_period_s) or max(3, 2*stroke_period_s). sensitivity_windows uses the requested main window and permits a separate sensitivity summary.}
\item{running_mean_window_s}{\if{latex}{\out{\sloppy}} Requested centred averaging-window duration in seconds. Used by custom_window_s and the main result of sensitivity_windows; fixed_3s overrides it. Rounded to samples using fs_hz.}
\item{stroke_period_s}{\if{latex}{\out{\sloppy}} Positive representative stroke/movement-cycle period in seconds, required for stroke_period_1x/2x. The function does not estimate a movement period.}
\item{lowpass_cutoff_hz}{\if{latex}{\out{\sloppy}} Low-pass cutoff in Hz when static_dynamic_method is low_pass_static_filter. Filter each axis and subtract that static estimate before forming the feature.}
\item{highpass_cutoff_hz}{\if{latex}{\out{\sloppy}} High-pass cutoff in Hz when static_dynamic_method is high_pass_dynamic_filter. The filtered axes are the dynamic components.}
\item{filter_type}{\if{latex}{\out{\sloppy}} Implementation identifier: butterworth is supported for low-/high-pass separation. This is not an automatic choice among filter families.}
\item{filter_order}{\if{latex}{\out{\sloppy}} Order passed to signal::butter for the forward/reverse separation filter. The double-pass frequency response differs from a single pass.}
\item{pdba_axes}{\if{latex}{\out{\sloppy}} Axis names selected for PDBA, from x, y and z. Default x/y sums their absolute dynamic components. This option does not change ODBA or VEDBA.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output acceleration unit: mg multiplies the epoch result by 1000; g retains the input scale.}
\item{edge_handling}{\if{latex}{\out{\sloppy}} Supported rule partial_centered_window: near signal boundaries, average only the available samples within the centred running window; no external padding is added.}
\item{missing_data_policy}{\if{latex}{\out{\sloppy}} Supported rule mean_na_rm: ignore missing observations when calculating local means and epoch means; all-missing estimates remain undefined. This is not gap repair.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (g or mg according to the selected output unit).}

\details{\if{latex}{\out{\sloppy}} Separate static/dynamic axes by the selected implemented method, form ODBA, VEDBA or PDBA, then average within epochs. The centred-window method uses partial available windows at boundaries. A different separation window/filter defines a different pipeline. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_odba} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Output settings}{
The \code{odba_settings} attribute records the selected metric, separation method, requested/resolved window duration, cycle-period rule, filter settings, selected axes, output unit and missing-data/edge policies. The direct helper returns one selected metric, not a list of multiple features. The summary function provides separately requested ODBA, VEDBA and PDBA columns.
}
