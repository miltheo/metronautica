\name{static_noise_summary_from_tbl}
\alias{static_noise_summary_from_tbl}
\title{Summarise stationary axis noise}
\description{\if{latex}{\out{\sloppy}} Summarise stationary axis noise.}
\usage{
static_noise_summary_from_tbl(x, instrument = NA_character_,
    device_id = NA_character_, device_vendor = NA_character_,
    device_model = NA_character_, fs_nominal_hz = NA_real_,
    fs_derived_hz = NA_real_, out_dir = NULL, start_utc, duration_h,
    verbose = FALSE, progress = TRUE)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration data frame/tibble with POSIXct time and numeric ax_g, ay_g, az_g in \eqn{g}, or a parser/clip bundle containing data/full and optional meta. The data attribute takes precedence over bundle metadata. No samples are repaired by input conversion.}
\item{instrument}{\if{latex}{\out{\sloppy}} Optional character label identifying the instrument in summaries and filenames; otherwise use vendor/model metadata when available.}
\item{device_id}{\if{latex}{\out{\sloppy}} Optional unit identifier for summaries and filenames; otherwise use acquisition$device_id metadata. This label does not select calibration coefficients.}
\item{device_vendor}{\if{latex}{\out{\sloppy}} Optional manufacturer label; otherwise use acquisition metadata. Does not alter decoding or calculations.}
\item{device_model}{\if{latex}{\out{\sloppy}} Optional device-model label; otherwise use acquisition metadata. Does not alter decoding or calculations.}
\item{fs_nominal_hz}{\if{latex}{\out{\sloppy}} Optional nominal recording frequency in Hz for summary identification; acquisition metadata supplies the fallback. Static calculations use their implemented timestamp-derived frequency, rather than this label.}
\item{fs_derived_hz}{\if{latex}{\out{\sloppy}} Optional timestamp-derived frequency label in Hz for the summary; metadata/timestamps provide a fallback. It does not override the implemented static calculation windows.}
\item{out_dir}{\if{latex}{\out{\sloppy}} NULL returns results in memory without writing files. Otherwise, create/use this output directory for the documented CSV, RDS and diagnostic plot files.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{duration_h}{\if{latex}{\out{\sloppy}} Required positive window duration in hours; the end is exclusive. No duration is assumed. Requested bounds, actual sample span and boundary coverage are retained in processing$static_window metadata. Incomplete boundary coverage warns; this is not an internal-gap or stationarity test.}
\item{verbose}{\if{latex}{\out{\sloppy}} Logical; print processing messages. Does not change calculations.}
\item{progress}{\if{latex}{\out{\sloppy}} Logical; display a text progress bar. Does not change calculations.}
}
\value{\if{latex}{\out{\sloppy}} An invisible list containing summary (one-row noise/identifier table), clipped_data (selected acceleration table), meta (including static-window coverage) and files (written paths, or NULL). This is not itself a one-row table.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{static_noise_summary_from_tbl} in \code{R/m_static.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Summary fields}{
\if{latex}{\out{\sloppy}}
Noise and variability fields follow \code{\link{static_axis_noise_metrics}}; the report adds instrument/unit labels, nominal/derived frequency labels in Hz, actual first-to-last sample duration in hours and observed clip bounds. The selected data and boundary-coverage metadata are returned separately. This report does not calculate drift, initial VM offset or Allan curves; use \code{\link{static_metrology_from_tbl}} for those outcomes.
}
