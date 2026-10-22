\name{plot_processed_metric}
\alias{plot_processed_metric}
\title{Plot an epoch-level acceleration feature}
\description{\if{latex}{\out{\sloppy}} Plot an epoch-level acceleration feature.}
\usage{
plot_processed_metric(result, metric, unit = NULL, title = metric)
}
\arguments{
\item{result}{\if{latex}{\out{\sloppy}} Summary result from compute_accel_summaries or its data_wide table.}
\item{metric}{\if{latex}{\out{\sloppy}} Name of the numeric column to plot from the processed summary table.}
\item{unit}{\if{latex}{\out{\sloppy}} Unit label displayed on the processed plot; does not rescale values. NULL uses result$settings$metric_units. Supply a label explicitly for a bare data_wide table or older outputs without this metadata; no mg unit is assumed.}
\item{title}{\if{latex}{\out{\sloppy}} Optional plot title.}
}
\value{\if{latex}{\out{\sloppy}} An interactive Plotly htmlwidget; no feature values are recalculated.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{plot_processed_metric} in \code{R/m_plotter.R}. See \code{\link{implementation-guide}} for the framework and function map.}
