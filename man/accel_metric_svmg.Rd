\name{accel_metric_svmg}
\alias{accel_metric_svmg}
\title{Compute gravity-subtracted vector magnitude}
\description{\if{latex}{\out{\sloppy}} Compute gravity-subtracted vector magnitude.}
\usage{
accel_metric_svmg(tbl, epoch_s, fs_hz, anchor = "center", output =
    c("g_seconds", "sample_sum_g", "mean_mg", "mean_g"), rectify =
    TRUE)
}
\arguments{
\item{tbl}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full. Input conversion preserves values and metadata.}
\item{epoch_s}{\if{latex}{\out{\sloppy}} Positive output-epoch duration in seconds. Samples are grouped by elapsed time from the first sample; the final partial epoch is retained. Different epoch lengths define different processing pipelines.}
\item{fs_hz}{\if{latex}{\out{\sloppy}} Sampling frequency in Hz. Used to convert durations to sample windows or sums to time integrals. Supply one finite positive scalar. A NULL estimate is available only where shown in Usage.}
\item{anchor}{\if{latex}{\out{\sloppy}} Output timestamp: start selects the first observed sample in an epoch, end the last, and center the middle observed sample (ceiling of half the epoch sample count). This labels the result without changing values.}
\item{output}{\if{latex}{\out{\sloppy}} g_seconds integrates the gravity-subtracted series by sum/fs_hz; sample_sum_g returns its sample sum; mean_mg and mean_g return its epoch mean in mg/g.}
\item{rectify}{\if{latex}{\out{\sloppy}} TRUE takes abs(VM - 1); FALSE retains the signed VM-minus-1-g series. This differs from the non-negative truncation used by ENMO.}
}
\value{A tibble with \code{time} (the selected observed-sample epoch label), \code{epoch_id} (integer elapsed-time bin starting at one), and \code{value} (g seconds for g_seconds, g sample sums for sample_sum_g, mg for mean_mg, or g for mean_g).}

\details{\if{latex}{\out{\sloppy}} Subtract 1 g from sample VM, optionally take absolute differences, and aggregate by the selected output form. The SVMGS, SVMGSEC and SVMGMEAN variants use the absolute differences; ENMO instead truncates negative differences to zero. See \code{\link{measurement-definitions}} for calculation definitions. No additional device calibration is performed by choosing a feature.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{accel_metric_svmg} in \code{R/m_accel_summary_suite.R}. See \code{\link{implementation-guide}} for the framework and function map.}
