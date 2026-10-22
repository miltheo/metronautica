\name{accel_meta}
\alias{accel_meta}
\title{Read acceleration metadata}
\description{\if{latex}{\out{\sloppy}} Return metadata without modifying the signal.}
\usage{
accel_meta(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
}
\value{\if{latex}{\out{\sloppy}} The \code{meta} attribute, normally a list; \code{NULL} if absent.}
\seealso{\code{\link{metronautica-package}}}
\examples{
t0 <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
fs <- 100
s <- (0:5999) / fs
meta <- list(acquisition = list(fs_derived_hz = fs,
    fs_nominal_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(t0 + s, 0.1 * sin(2 * pi * 2 * s),
    0.1 * cos(2 * pi * 2 * s), 1 + 0.1 * sin(2 * pi * s), meta)
accel_meta(x)$acquisition
}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_meta} in \code{R/m_parsers.R}. See \code{\link{implementation-guide}} for the framework and function map.}
