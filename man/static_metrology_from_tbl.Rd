\name{static_metrology_from_tbl}
\alias{static_metrology_from_tbl}
\title{Characterise a stationary recording}
\description{\if{latex}{\out{\sloppy}} Estimate signed 1-\eqn{g} VM offset bias, drift rate, static noise floor and non-overlapping Allan deviation.}
\usage{
static_metrology_from_tbl(x, instrument = NA_character_, device_id =
    NA_character_, device_vendor = NA_character_, device_model =
    NA_character_, fs_nominal_hz = NA_real_, fs_derived_hz =
    NA_real_, out_dir = NULL, start_utc, duration_h,
    title_prefix = NULL, verbose = FALSE, progress = TRUE)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
\item{instrument}{\if{latex}{\out{\sloppy}} Instrument label for summaries/filenames; defaults to available vendor/model metadata.}
\item{device_id}{\if{latex}{\out{\sloppy}} Summary/filename unit label from acquisition$device_id; does not select calibration coefficients.}
\item{device_vendor}{\if{latex}{\out{\sloppy}} Manufacturer label from acquisition metadata; affects neither decoding nor calculations.}
\item{device_model}{\if{latex}{\out{\sloppy}} Model label from acquisition metadata; affects neither decoding nor calculations.}
\item{fs_nominal_hz}{\if{latex}{\out{\sloppy}} Nominal frequency label (Hz); defaults to acquisition metadata. Calculations retain their timestamp-derived rate.}
\item{fs_derived_hz}{\if{latex}{\out{\sloppy}} Derived frequency label (Hz); defaults to metadata/timestamps, without overriding calculation windows.}
\item{out_dir}{\if{latex}{\out{\sloppy}} Output directory for CSV, RDS and diagnostic plots; NULL keeps results in memory.}
\item{start_utc}{\if{latex}{\out{\sloppy}} UTC window start; POSIXct or parseable text.}
\item{duration_h}{\if{latex}{\out{\sloppy}} Required positive duration (h), with exclusive end. processing$static_window records requested bounds, observed span and boundary coverage. Incomplete boundary coverage warns; internal gaps and stationarity are not tested.}
\item{title_prefix}{\if{latex}{\out{\sloppy}} Plot-title prefix.}
\item{verbose}{\if{latex}{\out{\sloppy}} Print processing messages.}
\item{progress}{\if{latex}{\out{\sloppy}} Show a text progress bar.}
}
\value{\if{latex}{\out{\sloppy}} An invisible list: \code{summary} (one-row table), \code{allan} (cluster durations and deviations), \code{drift_plot}, \code{allan_plot}, \code{clipped_data}, \code{one_hz} (axis/VM means and elapsed hours), \code{meta} and \code{files} (written paths, if requested).}
\details{\if{latex}{\out{\sloppy}} Stationarity must be established separately. The initial five-minute SD is raw; the full-window noise floor is detrended. \code{\link{measurement-definitions}} defines the outcomes and normalisation.}
\seealso{\code{\link{native-recording-examples}}}

\section{Summary fields}{
\if{latex}{\out{\sloppy}}
The one-row \code{summary} includes instrument/unit identifiers, actual first-to-last sample span in \code{trial_duration_h}, four \code{*_drift_g_per_h} slopes, \code{vm_offset_g_5min}, nominal/derived rate labels in Hz, and observed \code{clip_start_utc}/\code{clip_end_utc}. Axis/VM noise columns follow \code{\link{static_axis_noise_metrics}}. Axis-specific Allan minima and their evaluated averaging times follow \code{\link{static_allan_minima_wide}}. Actual sample span differs from requested window duration by endpoint sampling and any incomplete coverage; consult \code{meta$processing$static_window}.
}
