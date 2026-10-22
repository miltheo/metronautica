\name{static_offset_vm_5min}
\alias{static_offset_vm_5min}
\title{Estimate signed one-g vector-magnitude offset bias}
\description{\if{latex}{\out{\sloppy}} Estimate signed one-g vector-magnitude offset bias.}
\usage{
static_offset_vm_5min(d1)
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second summary table returned by static_1hz_means, with elapsed_h and axis/VM mean columns. elapsed_h is time since the first populated UTC-second bin, in hours. This is a derived table, not a raw parser bundle.}
}
\value{\if{latex}{\out{\sloppy}} Signed initial-window VM offset in g relative to 1 g.}
\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Select one-second bins satisfying elapsed_h <= 5/60, average vm_mean and subtract 1 g. The inclusive elapsed-bin rule is retained exactly. This measures VM offset relative to gravity, not an axis-specific multi-orientation calibration.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_offset_vm_5min} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
