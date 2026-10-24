\name{parse_raw_auto}
\alias{parse_raw_auto}
\title{Decode a supported accelerometer file}
\description{\if{latex}{\out{\sloppy}} Detect the device format, decode acceleration in \eqn{g} and retain timestamp, parser and calibration provenance.}
\usage{
parse_raw_auto(path, return = c("data", "bundle"), verbose = FALSE,
    progress = FALSE, time_shift_s = 0, tz_parsed = "UTC",
    hash_sha256 = NULL, qc = TRUE, ...)
}
\arguments{
\item{path}{\if{latex}{\out{\sloppy}} Path to one existing device file.}
\item{return}{\if{latex}{\out{\sloppy}} Output form: \code{"data"} or \code{"bundle"}.}
\item{verbose}{\if{latex}{\out{\sloppy}} Print processing messages.}
\item{progress}{\if{latex}{\out{\sloppy}} Show a text progress bar.}
\item{time_shift_s}{\if{latex}{\out{\sloppy}} Additive timestamp shift in seconds. No clock-rate correction is inferred.}
\item{tz_parsed}{\if{latex}{\out{\sloppy}} Timezone for supported text timestamp decoding and Axivity CWA reading; output is tagged UTC. Binary formats may use device-defined time policies.}
\item{hash_sha256}{\if{latex}{\out{\sloppy}} Optional caller-supplied source digest. NULL computes it; a supplied digest is recorded, not independently verified.}
\item{qc}{\if{latex}{\out{\sloppy}} Run primary-five diagnostics after decoding (default TRUE). FALSE skips these diagnostics.}
\item{...}{\if{latex}{\out{\sloppy}} Named device-specific settings listed under Details. Pass only settings supported by the detected parser.}
}
\value{\if{latex}{\out{\sloppy}} An \code{accel_tbl}, or \code{list(data = accel_tbl, meta = list)}. Metadata records the source, acquisition settings, decoding/calibration operations and integrity diagnostics. The automatic parser identity is \code{"m_parsers"} in \code{meta$file$auto_parser} and \code{meta$processing$parser_library$name}; \code{meta$file$parser} identifies the device-specific decoder.}
\details{\if{latex}{\out{\sloppy}} Supported inputs: GENEActiv/SENS BIN, Axivity CWA/AX3 CSV, ActiGraph GT3X/LEAP CSV/LEAP AGSD and HBK G-Link CSV. Optional decoders are GENEAread, GGIRread (CWA fallback) and read.gt3x; missing dependencies and unsupported formats error without installing packages.

LEAP AGSD uses the shifted-reciprocal conversion verified against paired exports. Supported configuration: LEAP v2, dataVersion 3, firmware 2.1.0.106, 128 Hz, calibrationMethod 2. Other configurations error. Decoding coefficients do not establish independent calibration traceability.

Review timezone assumptions/shifts before pairing. Default QC is stored at meta$processing$qc with ruleset primary-five; standalone sourcing also requires m_qc.R.}
\seealso{\code{\link{common-data-format}}, \code{\link{qc_accel_tbl}}, \href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#real-recording-examples}{Recording examples}}

\section{Device-specific arguments through ...}{\if{latex}{\out{\sloppy}}
\describe{
\item{full_scale_range_g}{\if{latex}{\out{\sloppy}} Configured symmetric peak-to-peak axis span in \eqn{g}; 16 means -8 to +8 \eqn{g}. Use file metadata when available or supply the documented acquisition setting. It affects range diagnostics and later normalisation, not already decoded CSV acceleration values. Observed minimum/maximum values are not a substitute for sensor limits.}
\item{GENEActiv calibrate}{\if{latex}{\out{\sloppy}} Logical, default TRUE. Forwarded to GENEAread::read.bin to control upstream coefficient application. This is device-file decoding/calibration, not the within-trial dynamic VM mapping. The returned provenance records whether upstream calibration was requested. mmap_load controls memory-mapped loading, default enabled on 64-bit R, without adding an analysis filter.}
\item{SENS scale_g_per_lsb}{\if{latex}{\out{\sloppy}} Acceleration scale converting signed axis counts to \eqn{g}; default 0.0078125 from the supported vendor binary specification. A different value requires device-format justification and changes decoded acceleration. No per-file offset or temperature correction is inferred.}
\item{GT3X precision}{\if{latex}{\out{\sloppy}} Default \code{"native"} preserves original integer-sample precision through file-scale conversion for supported modern log.bin containers, using the validated read.gt3x 1.2.0 interface. \code{"legacy_3dp"} selects the earlier upstream scaled/rounded output. Precision and native recording start are recorded in metadata. Native mode does not impute gaps or extract light; choose the explicit legacy mode for those upstream options. Older activity.bin layouts require legacy mode. No lost precision is inferred from CSV or rounded input.}
\item{GT3X imputeZeroes}{\if{latex}{\out{\sloppy}} Logical, default FALSE: retain the supported upstream decoder's non-imputation route. Enabling it changes the decoded treatment of missing/idle data and must be reported. add_light defaults FALSE; cleanup controls upstream extraction-file cleanup.}
\item{Axivity CWA settings}{\if{latex}{\out{\sloppy}} use_ggir_fallback defaults TRUE and permits the optional GGIRread path when the fast packed-AX3 layout is unsupported. interpolationType is passed to the fallback reader (default 1). Fast and fallback implementations and their scaling/time policies are retained in metadata; the caller should inspect the selected parser.}
\item{Sensor identifiers}{\if{latex}{\out{\sloppy}} sensor_vendor and sensor_model optionally annotate the sensor hardware. They do not select conversion coefficients or establish calibration traceability. Only pass arguments accepted by the detected parser.}
}
}
