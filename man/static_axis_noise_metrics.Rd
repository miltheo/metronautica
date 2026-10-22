\name{static_axis_noise_metrics}
\alias{static_axis_noise_metrics}
\title{Compute axis-specific stationary noise measures}
\description{\if{latex}{\out{\sloppy}} Compute axis-specific stationary noise measures.}
\usage{
static_axis_noise_metrics(x, cv_min_abs_mean_g = 0.005)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{cv_min_abs_mean_g}{\if{latex}{\out{\sloppy}} Absolute mean-acceleration threshold in \eqn{g} below which a coefficient of variation is returned as NA. Default 0.005 \eqn{g} avoids unstable division for axes close to zero mean.}
}
\value{\if{latex}{\out{\sloppy}} One-row tibble with raw and linearly detrended sample SDs, first-five-minute raw SDs, CVs, ranges and maximum-/median-axis summaries. Acceleration fields use \eqn{g} unless their name explicitly specifies m\eqn{g}; CV fields are percentages.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_axis_noise_metrics} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Returned fields}{
\if{latex}{\out{\sloppy}}
For each prefix x, y, z and vm, the one-row output contains \code{n} (finite samples used), \code{mean_g}, \code{sd_g} (sample SD), \code{detrended_sd_g} (linear-residual SD), \code{sd_5min_g} (raw SD within the first five minutes, inclusive boundary), \code{min_g}, \code{max_g}, \code{range_g}, \code{cv_percent} and \code{detrended_cv_percent}. Each prefix is joined to the field name by an underscore. Linear-residual SD uses n-2; raw SD uses n-1.

\code{max_axis_sd_g} and \code{median_axis_sd_g} summarise raw X/Y/Z SDs; \code{max_axis_noise_sd_g} and \code{median_axis_noise_sd_g} summarise detrended X/Y/Z SDs. Their maximum-axis identifiers end in \code{_axis}; analogous \code{sd_5min} fields use the initial raw window. \code{static_n_samples} counts supplied rows.

\code{static_noise_floor_mg} is 1000 times maximum-axis detrended SD. The retained \code{static_noise_floor_5min_mg} field is instead 1000 times initial raw maximum-axis SD; it is not detrended. \code{static_raw_max_axis_sd_mg} is the full-window raw maximum-axis SD in m\eqn{g}. \code{vm_sd_mg}, \code{vm_noise_sd_mg} and \code{vm_sd_5min_mg} give VM raw, detrended and initial raw SDs in m\eqn{g}; \code{vm_noise_cv_percent} is detrended VM CV. These operational outcomes do not independently establish stationarity.
}
