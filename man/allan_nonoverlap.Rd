\name{allan_nonoverlap}
\alias{allan_nonoverlap}
\title{Compute non-overlapping Allan deviation of a time series}
\description{\if{latex}{\out{\sloppy}} Allan deviation from successive non-overlapping cluster means.}
\usage{
allan_nonoverlap(x, fs_hz, tau_s, min_M = 4L)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Numeric one-axis sequence (\eqn{g}) at the supplied sampling frequency; not a table/bundle.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Finite positive sampling frequency (Hz), used for sample windows or time integrals.}
\item{tau_s}{\if{latex}{\out{\sloppy}} Requested averaging times (s), rounded to sample counts. Duplicate counts and unsupported long windows are omitted.}
\item{min_M}{\if{latex}{\out{\sloppy}} Minimum cluster count per averaging time (default four). Shorter supported times yield more adjacent-cluster differences.}
}
\value{\if{latex}{\out{\sloppy}} A tibble containing tau in seconds and adev in the input signal unit.}
\seealso{\code{\link{static_allan}}, \code{\link{measurement-definitions}}}

\section{Method}{\if{latex}{\out{\sloppy}} Round tau_s to sample counts; form complete non-overlapping clusters and calculate sqrt(mean(diff(cluster_means)^2)/2). Omit unsupported lengths and trailing incomplete clusters. Returned tau equals cluster sample count/fs_hz.}
