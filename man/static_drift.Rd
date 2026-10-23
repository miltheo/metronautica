\name{static_drift}
\alias{static_drift}
\title{Estimate signed drift from one-second means}
\description{\if{latex}{\out{\sloppy}} Signed OLS slopes of one-second axis and VM means against elapsed hours.}
\usage{
static_drift(d1)
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second means from \code{\link{static_1hz_means}}, including elapsed_h (hours since the first populated UTC-second bin).}
}
\value{\if{latex}{\out{\sloppy}} A list with \code{vm_drift_g_per_h}, \code{x_drift_g_per_h}, \code{y_drift_g_per_h} and \code{z_drift_g_per_h}: signed slopes in \eqn{g}/h. \code{fit_vm} is the fitted VM \code{lm} object. Fitted axis-model objects are not returned.}

\seealso{\code{\link{static_1hz_means}}, \code{\link{plot_static_drift_vm}}, \code{\link{measurement-definitions}}}

\section{Method}{\if{latex}{\out{\sloppy}} Fit separate OLS models of one-second axis/VM means against elapsed_h. Requires a stationary interval; a slope fitted to uncontrolled movement does not establish sensor drift.}
