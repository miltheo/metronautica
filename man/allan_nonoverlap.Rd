\name{allan_nonoverlap}
\alias{allan_nonoverlap}
\title{Compute non-overlapping Allan deviation of a time series}
\description{\if{latex}{\out{\sloppy}} Compute non-overlapping Allan deviation of a time series.}
\usage{
allan_nonoverlap(x, fs_hz, tau_s, min_M = 4L)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Numeric one-axis acceleration sequence in \eqn{g}, ordered at the supplied sampling frequency. It is not an acceleration table or parser bundle.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{tau_s}{\if{latex}{\out{\sloppy}} Requested Allan averaging times in seconds. Each is rounded to an integer number of samples; duplicate sample counts are removed and unsupported long windows are omitted.}
\item{min_M}{\if{latex}{\out{\sloppy}} Minimum number of non-overlapping clusters required at a candidate averaging time. Default four; smaller supported averaging times provide more adjacent-cluster differences.}
}
\value{\if{latex}{\out{\sloppy}} A tibble containing tau in seconds and adev in the input signal unit.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Convert tau_s to rounded sample counts and divide the sequence into complete non-overlapping clusters. Compute each cluster mean, then sqrt(mean(diff(cluster_means)^2)/2). Omit unsupported cluster lengths and trailing incomplete clusters. Returned tau is the actual sample count divided by fs_hz.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{allan_nonoverlap} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
