\name{plot_static_drift_vm}
\alias{plot_static_drift_vm}
\title{Plot signed vector-magnitude drift}
\description{\if{latex}{\out{\sloppy}} One-second VM means and their fitted drift line.}
\usage{
plot_static_drift_vm(d1, drift_fit, title_prefix = "Static drift")
}
\arguments{
\item{d1}{\if{latex}{\out{\sloppy}} One-second means from \code{\link{static_1hz_means}}, including elapsed_h (hours since the first populated UTC-second bin).}
\item{drift_fit}{\if{latex}{\out{\sloppy}} The fitted linear model, obtained as \code{static_drift(d1)$fit_vm}.}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Plot-title prefix.}
}
\value{\if{latex}{\out{\sloppy}} ggplot object; data are unchanged.}
\seealso{\code{\link{static_1hz_means}}, \code{\link{static_drift}}}
