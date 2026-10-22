\name{static_allan}
\alias{static_allan}
\title{Compute axis-specific non-overlapping Allan deviation}
\description{\if{latex}{\out{\sloppy}} Compute axis-specific non-overlapping Allan deviation.}
\usage{
static_allan(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
}
\value{\if{latex}{\out{\sloppy}} A tibble containing tau, adev in g and axis identifiers.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} For each axis, evaluate 60 log-spaced requested averaging times from 0.1 to 10000 seconds through allan_nonoverlap. Sampling frequency is estimated from positive timestamp intervals. The calculation assumes suitable uniformly sampled stationary data; it does not repair gaps or resample. The minimum four-cluster requirement limits supported long averaging times.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_allan} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
