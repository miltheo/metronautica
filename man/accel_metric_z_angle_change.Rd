\name{accel_metric_z_angle_change}
\alias{accel_metric_z_angle_change}
\title{Compute change in Z-axis angle}
\description{\if{latex}{\out{\sloppy}} Epoch mean or maximum absolute successive change in smoothed Z-angle.}
\usage{
accel_metric_z_angle_change(tbl, epoch_s, fs_hz, anchor = "center",
    median_s = 5, output = c("mean_abs_change_deg",
    "max_abs_change_deg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{median_s}{\if{latex}{\out{\sloppy}} Running-median duration (s), converted with fs_hz to an odd sample count of at least three; smooths the change/orientation series before aggregation.}
\item{output}{\if{latex}{\out{\sloppy}} mean_abs_change_deg averages successive absolute differences of the smoothed Z-angle within each epoch; max_abs_change_deg returns their maximum. Neither is divided by elapsed time.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected sample label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (degrees per successive-sample change, without division by elapsed time).}

\details{\if{latex}{\out{\sloppy}} Compute full-vector Z-angle, apply the selected running median, then form successive absolute differences. Summarise the differences within epochs. It measures change per successive sample, not angular velocity.}
\seealso{\code{\link{compute_accel_summaries}}}
