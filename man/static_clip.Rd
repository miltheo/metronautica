\name{static_clip}
\alias{static_clip}
\title{Select a stationary assessment interval}
\description{\if{latex}{\out{\sloppy}} Select a stationary assessment interval.}
\usage{
static_clip(x, start_utc, duration_h)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{duration_h}{\if{latex}{\out{\sloppy}} Required positive window duration in hours; the end is exclusive. No duration is assumed. Requested bounds, actual sample span and boundary coverage are retained in processing$static_window metadata. Incomplete boundary coverage warns; this is not an internal-gap or stationarity test.}
}
\value{\if{latex}{\out{\sloppy}} The selected acceleration table; the end of the static interval is excluded.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_clip} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Container behaviour}{
\if{latex}{\out{\sloppy}}
Returns an acceleration table for both table and bundle input. A supplied parser bundle is unwrapped from \code{data}; a dynamic bundle is unwrapped from \code{full}. Metadata is attached to the selected table; no stage bundle is returned or updated. Each selected interval receives freshly computed QC.
}
