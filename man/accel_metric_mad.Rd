\name{accel_metric_mad}
\alias{accel_metric_mad}
\title{Compute mean amplitude deviation}
\description{\if{latex}{\out{\sloppy}} Compute mean amplitude deviation.}
\usage{
accel_metric_mad(tbl, epoch_s, anchor = "center", out_unit = c("mg",
    "g"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output acceleration unit: m\eqn{g} multiplies the epoch result by 1000; \eqn{g} retains the input scale.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (\eqn{g} or m\eqn{g} according to the selected output unit).}

\details{\if{latex}{\out{\sloppy}} Within each epoch, calculate VM and average its absolute deviations from that epoch's VM mean. This is the mean amplitude deviation definition. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_mad} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\references{Vaha-Ypya et al. (2015), A universal, accurate intensity-based classification of different physical activities using raw data of accelerometer. \doi{10.1111/cpf.12127}.}
