\name{accel_metric_vm}
\alias{accel_metric_vm}
\title{Compute vector magnitude}
\description{\if{latex}{\out{\sloppy}} Epoch mean, sample SD, maximum or 95th percentile of VM.}
\usage{
accel_metric_vm(tbl, epoch_s, anchor = "center", summary_fun =
    c("mean", "sd", "max", "p95"), out_unit = c("g", "mg"))
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{summary_fun}{\if{latex}{\out{\sloppy}} Within-epoch statistic of sample VM: mean, sample SD, maximum, or the R type-7 95th percentile.}
\item{out_unit}{\if{latex}{\out{\sloppy}} \eqn{g} retains the VM statistic; m\eqn{g} multiplies it by 1000.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected epoch label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (selected \eqn{g} or m\eqn{g} unit).}

\details{\if{latex}{\out{\sloppy}} Compute sample VM as sqrt(ax_g^2 + ay_g^2 + az_g^2), then the selected epoch statistic.}
\seealso{\code{\link{compute_accel_summaries}}}
