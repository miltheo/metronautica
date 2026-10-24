\name{accel_metric_rocam}
\alias{accel_metric_rocam}
\title{Compute rate-of-change acceleration movement}
\description{\if{latex}{\out{\sloppy}} Epoch mean Euclidean sample-to-sample triaxial acceleration change, after running-median smoothing.}
\usage{
accel_metric_rocam(tbl, epoch_s, fs_hz, anchor = "center", median_s
    = 1)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); see the pipeline epoch conventions in \code{\link{compute_accel_summaries}}.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{median_s}{\if{latex}{\out{\sloppy}} Running-median duration (s), converted with fs_hz to an odd sample count of at least three; smooths the difference series before aggregation.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected sample label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (\eqn{g} per successive-sample change, without division by elapsed time).}

\details{\if{latex}{\out{\sloppy}} Default smoothing is a one-second running median of the difference series. No time division or one-second resampling: units are \eqn{g}/sample change, not \eqn{g}/s.}
\seealso{\code{\link{compute_accel_summaries}}}
