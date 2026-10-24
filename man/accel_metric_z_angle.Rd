\name{accel_metric_z_angle}
\alias{accel_metric_z_angle}
\title{Compute Z-axis angle}
\description{\if{latex}{\out{\sloppy}} Epoch mean or sample SD of the full-vector Z-angle.}
\usage{
accel_metric_z_angle(tbl, epoch_s, anchor = "center", output =
    c("mean_deg", "sd_deg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); see the pipeline epoch conventions in \code{\link{compute_accel_summaries}}.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{output}{\if{latex}{\out{\sloppy}} mean_deg returns the epoch mean Z-angle; sd_deg returns its sample SD. Both are in degrees.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected sample label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (degrees).}

\details{\if{latex}{\out{\sloppy}} For each sample compute atan(z/sqrt(x^2+y^2)) in degrees, then take the selected epoch mean or SD. No low-pass gravity-vector estimate is introduced; this is the full-vector orientation feature.}
\seealso{\code{\link{compute_accel_summaries}}}
