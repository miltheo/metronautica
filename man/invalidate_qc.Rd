\name{invalidate_qc}
\alias{invalidate_qc}
\title{Remove diagnostics inherited from an earlier signal state}
\description{\if{latex}{\out{\sloppy}} Remove stored QC after signal changes.}
\usage{
invalidate_qc(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} The same input container with inherited QC removed; acceleration samples are unchanged.}
\seealso{\code{\link{attach_qc}}, \code{\link{common-data-format}}}
