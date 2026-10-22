\name{accel_metric_z_angle_change}
\alias{accel_metric_z_angle_change}
\title{Compute change in Z-axis angle}
\description{\if{latex}{\out{\sloppy}} Compute change in Z-axis angle.}
\usage{
accel_metric_z_angle_change(tbl, epoch_s, fs_hz, anchor = "center",
    median_s = 5, output = c("mean_abs_change_deg",
    "max_abs_change_deg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{median_s}{\if{latex}{\out{\sloppy}} Running-median duration in seconds; converted using fs_hz to an odd sample count of at least three. Used to smooth the change or orientation series before epoch summarisation.}
\item{output}{\if{latex}{\out{\sloppy}} mean_abs_change_deg averages successive absolute differences of the smoothed Z-angle within each epoch; max_abs_change_deg returns their maximum. Neither is divided by elapsed time.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (degrees per successive-sample change, without division by elapsed time).}

\details{\if{latex}{\out{\sloppy}} Compute full-vector Z-angle, apply the selected running median, then form successive absolute differences. Summarise the differences within epochs. It measures change per successive sample, not angular velocity. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_z_angle_change} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}
