\name{accel_metric_z_angle}
\alias{accel_metric_z_angle}
\title{Compute Z-axis angle}
\description{\if{latex}{\out{\sloppy}} Compute Z-axis angle.}
\usage{
accel_metric_z_angle(tbl, epoch_s, anchor = "center", output =
    c("mean_deg", "sd_deg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{output}{\if{latex}{\out{\sloppy}} mean_deg returns the epoch mean Z-angle; sd_deg returns its sample SD. Both are in degrees, using atan(z/sqrt(x^2+y^2)).}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (degrees).}

\details{\if{latex}{\out{\sloppy}} For each sample compute atan(z/sqrt(x^2+y^2)) in degrees, then take the selected epoch mean or SD. No low-pass gravity-vector estimate is introduced; this is the full-vector orientation feature in the approved definition. See \code{\link{measurement-definitions}} for manuscript-aligned definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_z_angle} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
