\name{static_drift}
\alias{static_drift}
\title{Estimate signed drift from one-second means}
\description{\if{latex}{\out{\sloppy}} Estimate signed drift from one-second means.}
\usage{
static_drift(d1)
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second summary table returned by static_1hz_means, with elapsed_h and axis/VM mean columns. elapsed_h is time since the first populated UTC-second bin, in hours. This is a derived table, not a raw parser bundle.}
}
\value{A list with \code{vm_drift_g_per_h}, \code{x_drift_g_per_h}, \code{y_drift_g_per_h} and \code{z_drift_g_per_h}: signed slopes in \eqn{g}/h. \code{fit_vm} is the fitted VM \code{lm} object. Fitted axis-model objects are not returned.}

\seealso{\code{\link{metronautica-package}}}

\section{Method}{\if{latex}{\out{\sloppy}} Fit separate ordinary least-squares models of one-second VM and axis means on elapsed_h. Return the signed slopes in \eqn{g}/h and the fitted VM model. Selection of a stationary interval is the caller's responsibility; fitting a slope does not establish physical sensor drift in uncontrolled movement.}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_drift} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}
