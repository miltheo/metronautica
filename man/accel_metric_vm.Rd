\name{accel_metric_vm}
\alias{accel_metric_vm}
\title{Compute vector magnitude}
\description{\if{latex}{\out{\sloppy}} Compute vector magnitude.}
\usage{
accel_metric_vm(tbl, epoch_s, anchor = "center", summary_fun =
    c("mean", "sd", "max", "p95"), out_unit = c("g", "mg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{summary_fun}{\if{latex}{\out{\sloppy}} Within-epoch statistic of sample VM: mean, sample SD, maximum, or the R type-7 95th percentile.}
\item{out_unit}{\if{latex}{\out{\sloppy}} \eqn{g} retains the VM statistic; m\eqn{g} multiplies it by 1000.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (\eqn{g} or m\eqn{g} according to the selected output unit).}

\details{\if{latex}{\out{\sloppy}} Compute sample vector magnitude and the selected within-epoch statistic; return \eqn{g} or m\eqn{g}. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_vm} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}
