\name{static_metrology_from_tbl}
\alias{static_metrology_from_tbl}
\title{Characterise a stationary recording}
\description{\if{latex}{\out{\sloppy}} Estimate stationary offset, linear drift, signal noise and non-overlapping Allan deviation.}
\usage{
static_metrology_from_tbl(x, instrument = NA_character_, device_id =
    NA_character_, device_vendor = NA_character_, device_model =
    NA_character_, fs_nominal_hz = NA_real_, fs_derived_hz =
    NA_real_, out_dir = NULL, start_utc, duration_h,
    title_prefix = NULL, verbose = FALSE, progress = TRUE)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in g, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{instrument}{\if{latex}{\out{\sloppy}} Optional character label identifying the instrument in summaries and filenames; otherwise use vendor/model metadata when available.}
\item{device_id}{\if{latex}{\out{\sloppy}} Optional unit identifier for summaries and filenames; otherwise use acquisition$device_id metadata. This label does not select calibration coefficients.}
\item{device_vendor}{\if{latex}{\out{\sloppy}} Optional manufacturer label; otherwise use acquisition metadata. Does not alter decoding or calculations.}
\item{device_model}{\if{latex}{\out{\sloppy}} Optional device-model label; otherwise use acquisition metadata. Does not alter decoding or calculations.}
\item{fs_nominal_hz}{\if{latex}{\out{\sloppy}} Optional nominal recording frequency in Hz for summary identification; acquisition metadata supplies the fallback. Static calculations use their implemented timestamp-derived frequency, rather than this label.}
\item{fs_derived_hz}{\if{latex}{\out{\sloppy}} Optional timestamp-derived frequency label in Hz for the summary; metadata/timestamps provide a fallback. It does not override the implemented static calculation windows.}
\item{out_dir}{\if{latex}{\out{\sloppy}} NULL returns results in memory without writing files. Otherwise, create/use this output directory for the documented CSV, RDS and diagnostic plot files.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{duration_h}{\if{latex}{\out{\sloppy}} Required positive window duration in hours; the end is exclusive. No duration is assumed. Requested bounds, actual sample span and boundary coverage are retained in processing$static_window metadata. Incomplete boundary coverage warns; this is not an internal-gap or stationarity test.}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Character prefix for diagnostic plot titles; does not change computed outcomes.}
\item{verbose}{\if{latex}{\out{\sloppy}} Logical; print processing messages. Does not change calculations.}
\item{progress}{\if{latex}{\out{\sloppy}} Logical; display a text progress bar. Does not change calculations.}
}
\value{\if{latex}{\out{\sloppy}} An invisible list: \code{summary} (one-row table), \code{allan} (cluster durations and deviations), \code{drift_plot}, \code{allan_plot}, \code{clipped_data}, \code{one_hz} (axis/VM means and elapsed hours), \code{meta} and \code{files} (written paths, if requested).}
\details{\if{latex}{\out{\sloppy}} Offset is the mean one-second vector magnitude over \code{elapsed_h <= 5/60}, minus 1 g. Drift is the least-squares slope of one-second means against elapsed hours, in g/h. Static noise floor is the maximum axis-specific residual SD after linear detrending over the selected window, reported in mg. The first-five-minute maximum-axis SD is raw, not detrended. Raw SD uses \eqn{n-1}; linearly detrended residual SD uses \eqn{n-2}. The stationary coefficient of variation is a percentage with a near-zero mean guard. Allan deviation uses non-overlapping cluster means. The maximum-axis Allan minimum is derived as the maximum of the three individual axis minima over evaluated averaging times. Full definitions are in \code{\link{measurement-definitions}}. The input window must be stationary; the function does not establish that condition or infer a sensor calibration.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_metrology_from_tbl} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Summary fields}{
\if{latex}{\out{\sloppy}}
The one-row \code{summary} includes instrument/unit identifiers, actual first-to-last sample span in \code{trial_duration_h}, four \code{*_drift_g_per_h} slopes, \code{vm_offset_g_5min}, nominal/derived rate labels in Hz, and observed \code{clip_start_utc}/\code{clip_end_utc}. Axis/VM noise columns follow \code{\link{static_axis_noise_metrics}}. Axis-specific Allan minima and their evaluated averaging times follow \code{\link{static_allan_minima_wide}}. Actual sample span differs from requested window duration by endpoint sampling and any incomplete coverage; consult \code{meta$processing$static_window}.
}
