\name{static_noise_summary_from_tbl}
\alias{static_noise_summary_from_tbl}
\title{Summarise stationary axis noise}
\description{\if{latex}{\out{\sloppy}} Noise and variability for an explicitly selected stationary interval.}
\usage{
static_noise_summary_from_tbl(x, instrument = NA_character_,
    device_id = NA_character_, device_vendor = NA_character_,
    device_model = NA_character_, fs_nominal_hz = NA_real_,
    fs_derived_hz = NA_real_, out_dir = NULL, start_utc, duration_h,
    verbose = FALSE, progress = TRUE, attach_report = TRUE)
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
\item{verbose}{\if{latex}{\out{\sloppy}} Print processing messages.}
\item{progress}{\if{latex}{\out{\sloppy}} Show a text progress bar.}
\item{attach_report}{\if{latex}{\out{\sloppy}} TRUE (default) appends the noise assessment to processing$reports$static on returned data and clipped_data. FALSE adds no record. The caller's object is not modified in place.}
}
\value{\if{latex}{\out{\sloppy}} Invisible list: summary (one-row noise/identifier table), clipped_data, meta (including window coverage), files (written paths or NULL), and data (the complete input table with optional attached assessment). Attached results contain the noise summary; shared record fields and retention follow \code{\link{common-data-format}}.}
\seealso{\code{\link{static_axis_noise_metrics}}, \code{\link{static_metrology_from_tbl}}}

\section{Summary fields}{
\if{latex}{\out{\sloppy}}
Noise and variability fields follow \code{\link{static_axis_noise_metrics}}; the report adds instrument/unit labels, nominal/derived frequency labels in Hz, actual first-to-last sample duration in hours and observed clip bounds. The selected data and boundary-coverage metadata are returned separately. This report does not calculate drift, initial VM offset or Allan curves; use \code{\link{static_metrology_from_tbl}} for those outcomes.
}
