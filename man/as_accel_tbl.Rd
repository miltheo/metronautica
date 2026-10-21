\name{as_accel_tbl}
\alias{as_accel_tbl}
\title{Construct a common-format acceleration table}
\description{\if{latex}{\out{\sloppy}} Construct an acceleration table and retain its metadata. Parsing attaches diagnostics by default; they can also be attached explicitly.}
\usage{
as_accel_tbl(time, ax_g, ay_g, az_g, meta = list())
}
\arguments{
\item{time}{\if{latex}{\out{\sloppy}} POSIXct sample timestamps. UTC is the common-format convention; existing instants and timezone attributes are retained.}
\item{ax_g}{\if{latex}{\out{\sloppy}} Numeric X-axis acceleration in g.}
\item{ay_g}{\if{latex}{\out{\sloppy}} Numeric Y-axis acceleration in g.}
\item{az_g}{\if{latex}{\out{\sloppy}} Numeric Z-axis acceleration in g.}
\item{meta}{\if{latex}{\out{\sloppy}} Metadata list; see \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} An \code{accel_tbl} inheriting from \code{tbl_df}, with exactly \code{time}, \code{ax_g}, \code{ay_g}, \code{az_g} and a \code{meta} attribute.}
\details{\if{latex}{\out{\sloppy}} Axes must have the same length as time; scalar recycling is rejected. Non-finite observations and timestamp defects are retained for diagnostics. The constructor does not sort, resample, calibrate or infer acceleration units. The constructor preserves supplied metadata without estimating acquisition settings. The configured axis full-scale range is the peak-to-peak span: 16 g denotes +/-8 g.}
\seealso{\code{\link{metronautica-package}}}
\examples{
t0 <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
fs <- 100
s <- (0:5999) / fs
meta <- list(acquisition = list(fs_derived_hz = fs,
    fs_nominal_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(t0 + s, 0.1 * sin(2 * pi * 2 * s),
    0.1 * cos(2 * pi * 2 * s), 1 + 0.1 * sin(2 * pi * s), meta)
class(x)
qc_accel_tbl(x)$n_samples
}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{as_accel_tbl} in \code{R/m_parsers.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
