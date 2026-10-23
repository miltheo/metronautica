\name{static_offset_vm_5min}
\alias{static_offset_vm_5min}
\title{Estimate signed one-\eqn{g} vector-magnitude offset bias}
\description{\if{latex}{\out{\sloppy}} Initial five-minute mean VM minus 1 \eqn{g}.}
\usage{
static_offset_vm_5min(d1)
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second means from \code{\link{static_1hz_means}}, including elapsed_h (hours since the first populated UTC-second bin).}
}
\value{\if{latex}{\out{\sloppy}} Signed initial-window VM offset in \eqn{g} relative to 1 \eqn{g}.}
\seealso{\code{\link{static_1hz_means}}, \code{\link{measurement-definitions}}}

\section{Method}{\if{latex}{\out{\sloppy}} Select one-second bins satisfying elapsed_h <= 5/60, average vm_mean and subtract 1 \eqn{g}. The inclusive elapsed-bin rule is retained exactly. This measures VM offset relative to gravity, not an axis-specific multi-orientation calibration.}
