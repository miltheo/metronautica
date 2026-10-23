\name{accel_metric_svmg}
\alias{accel_metric_svmg}
\title{Compute gravity-subtracted vector magnitude}
\description{\if{latex}{\out{\sloppy}} Epoch integral, sample sum or mean of VM minus 1 \eqn{g}, optionally rectified.}
\usage{
accel_metric_svmg(tbl, epoch_s, fs_hz, anchor = "center", output =
    c("g_seconds", "sample_sum_g", "mean_mg", "mean_g"), rectify =
    TRUE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive epoch duration (s); boundaries follow the common data format.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{anchor}{\if{latex}{\out{\sloppy}} Observed-sample label: first (start), last (end), or ceiling of half the sample count (center). Labels do not change values.}
\item{output}{\if{latex}{\out{\sloppy}} g_seconds integrates the gravity-subtracted series by sum/fs_hz; sample_sum_g returns its sample sum; mean_mg and mean_g return its epoch mean in m\eqn{g}/\eqn{g}.}
\item{rectify}{\if{latex}{\out{\sloppy}} TRUE takes abs(VM - 1); FALSE retains the signed VM-minus-1-\eqn{g} series. This differs from the non-negative truncation used by ENMO.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{time} (selected sample label), \code{epoch_id} (elapsed-time bin, starting at one), \code{value} (\eqn{g} seconds for g_seconds, \eqn{g} sample sums for sample_sum_g, m\eqn{g} for mean_mg, or \eqn{g} for mean_g).}

\details{\if{latex}{\out{\sloppy}} SVMGS, SVMGSEC and SVMGMEAN use absolute VM-minus-1-\eqn{g} differences. Their sample sum, frequency-normalised integral and epoch mean are distinct outputs.}
\seealso{\code{\link{compute_accel_summaries}}}
