\name{attach_qc}
\alias{attach_qc}
\title{Attach signal diagnostics to recording metadata}
\description{\if{latex}{\out{\sloppy}} Compute and attach current primary-five signal diagnostics.}
\usage{
attach_qc(x, scope = "whole parsed recording")
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{scope}{\if{latex}{\out{\sloppy}} Text describing the recording interval to which the diagnostics apply.}
}
\value{\if{latex}{\out{\sloppy}} The same input container, with primary-five diagnostics in meta$processing$qc. Bundle and data metadata are synchronised.}
\seealso{\code{\link{qc_accel_tbl}}, \code{\link{invalidate_qc}}}
