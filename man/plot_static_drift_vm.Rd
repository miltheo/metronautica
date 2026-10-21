\name{plot_static_drift_vm}
\alias{plot_static_drift_vm}
\title{Plot signed vector-magnitude drift}
\description{\if{latex}{\out{\sloppy}} Plot signed vector-magnitude drift.}
\usage{
plot_static_drift_vm(d1, drift_fit, title_prefix = "Static drift")
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second summary table returned by static_1hz_means, with elapsed_h and axis/VM mean columns. elapsed_h is time since the first populated UTC-second bin, in hours. This is a derived table, not a raw parser bundle.}
\item{drift_fit}{\if{latex}{\out{\sloppy}} The fitted linear model, obtained as \code{static_drift(d1)$fit_vm}.}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Character prefix for diagnostic plot titles; does not change computed outcomes.}
}
\value{\if{latex}{\out{\sloppy}} A ggplot object; supplied data are unchanged.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{plot_static_drift_vm} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
