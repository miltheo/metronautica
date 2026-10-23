\name{static_clip}
\alias{static_clip}
\title{Select a stationary assessment interval}
\description{\if{latex}{\out{\sloppy}} Select an explicit time window and recompute QC.}
\usage{
static_clip(x, start_utc, duration_h)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{duration_h}{\if{latex}{\out{\sloppy}} Required positive duration (h), with exclusive end. processing$static_window records requested bounds, observed span and boundary coverage. Incomplete boundary coverage warns; internal gaps and stationarity are not tested.}
}
\value{\if{latex}{\out{\sloppy}} The selected acceleration table; the end of the static interval is excluded.}
\seealso{\code{\link{static_metrology_from_tbl}}, \code{\link{clip_bundle}}}

\section{Container behaviour}{
\if{latex}{\out{\sloppy}}
Returns an acceleration table for both table and bundle input. A supplied parser bundle is unwrapped from \code{data}; a dynamic bundle is unwrapped from \code{full}. Metadata is attached to the selected table; no stage bundle is returned or updated. Each selected interval receives freshly computed QC.
}
