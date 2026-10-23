\name{static_allan}
\alias{static_allan}
\title{Compute axis-specific non-overlapping Allan deviation}
\description{\if{latex}{\out{\sloppy}} Axis-wise Allan deviation over supported averaging times.}
\usage{
static_allan(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} Tibble: \code{axis}, \code{tau} (s), \code{adev} (\eqn{g}).}
\seealso{\code{\link{allan_nonoverlap}}, \code{\link{static_allan_minima_wide}}, \code{\link{plot_static_allan}}}

\section{Method}{\if{latex}{\out{\sloppy}} For each axis, request 60 log-spaced averaging times from 0.1 to 10000 s through \code{\link{allan_nonoverlap}}; at least four clusters are required. Rate is estimated from positive timestamp intervals. Requires uniformly sampled stationary data; gaps are neither repaired nor resampled.}
