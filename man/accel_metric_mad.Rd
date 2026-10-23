\name{accel_metric_mad}
\alias{accel_metric_mad}
\title{Compute mean amplitude deviation}
\description{\if{latex}{\out{\sloppy}} Epoch mean absolute deviation of VM from its epoch mean.}
\usage{
accel_metric_mad(tbl, epoch_s, anchor = "center", out_unit = c("mg",
    "g"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{out_unit}{\if{latex}{\out{\sloppy}} Output unit: \eqn{g}, or m\eqn{g} (result multiplied by 1000).}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected epoch label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (selected \eqn{g} or m\eqn{g} unit).}

\details{\if{latex}{\out{\sloppy}} For epoch VM values v, calculate mean(abs(v - mean(v))).}
\seealso{\code{\link{compute_accel_summaries}}}

\references{Vaha-Ypya et al. (2015), A universal, accurate intensity-based classification of different physical activities using raw data of accelerometer. \doi{10.1111/cpf.12127}.}
