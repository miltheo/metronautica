\name{parse_raw_auto}
\alias{parse_raw_auto}
\title{Decode a supported accelerometer file}
\description{\if{latex}{\out{\sloppy}} Detect the device format, decode acceleration in g and retain timestamp, parser and calibration provenance.}
\usage{
parse_raw_auto(path, return = c("data", "bundle"), verbose = FALSE,
    progress = FALSE, time_shift_s = 0, tz_parsed = "UTC",
    hash_sha256 = NULL, qc = TRUE, ...)
}
\arguments{
\item{path}{\if{latex}{\out{\sloppy}} Path to one existing device file.}
\item{return}{\if{latex}{\out{\sloppy}} Output form: \code{"data"} or \code{"bundle"}.}
\item{verbose}{\if{latex}{\out{\sloppy}} Logical; print processing messages. Does not change calculations.}
\item{progress}{\if{latex}{\out{\sloppy}} Logical; display a text progress bar. Does not change calculations.}
\item{time_shift_s}{\if{latex}{\out{\sloppy}} Additive timestamp shift in seconds. No clock-rate correction is inferred.}
\item{tz_parsed}{\if{latex}{\out{\sloppy}} Timezone for supported text timestamp decoding and Axivity CWA reading; output is tagged UTC. Binary formats may use device-defined time policies.}
\item{hash_sha256}{\if{latex}{\out{\sloppy}} Optional caller-supplied source digest. NULL computes it; a supplied digest is recorded, not independently verified.}
\item{qc}{\if{latex}{\out{\sloppy}} Run primary-five diagnostics after decoding (default TRUE). FALSE skips these diagnostics.}
\item{...}{\if{latex}{\out{\sloppy}} Named device-specific settings listed under Details. Only pass settings supported by the detected parser.}
}
\value{\if{latex}{\out{\sloppy}} An \code{accel_tbl}, or \code{list(data = accel_tbl, meta = list)}. Metadata records the source, acquisition settings, decoding/calibration operations and integrity diagnostics. The automatic parser identity is \code{"m_parsers"} in \code{meta$file$auto_parser} and \code{meta$processing$parser_library$name}; \code{meta$file$parser} identifies the device-specific decoder.}
\details{\if{latex}{\out{\sloppy}} Supported inputs are GENEActiv/SENS BIN, Axivity CWA/AX3 CSV, ActiGraph GT3X/LEAP CSV/LEAP AGSD and HBK G-Link CSV. GENEAread, GGIRread (CWA fallback) and read.gt3x are optional decoder dependencies. Unavailable dependencies or unsupported formats raise errors; packages are never installed during parsing. The AGSD calibration decoder is bounded to LEAP v2, dataVersion 3, firmware 2.1.0.106, 128 Hz and calibrationMethod 2. Unsupported configurations fail rather than being silently extrapolated. Device decoding coefficients do not establish an independently traceable calibration. Timezone assumptions and shifts must be reviewed before reference pairing. QC runs by default and is stored under meta$processing$qc with ruleset primary-five. A standalone source session must also load m_qc.R. The shifted-reciprocal LEAP conversion verified against paired device exports is the default; supported configuration checks are retained.}
\seealso{\code{\link{metronautica-package}}}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{parse_raw_auto} in \code{R/m_parsers.R}. See \code{\link{implementation-guide}} for the framework and function map.}

\section{Device-specific arguments through ...}{\if{latex}{\out{\sloppy}}
\describe{
\item{full_scale_range_g}{Configured symmetric peak-to-peak axis span in g; 16 means -8 to +8 g. Use file metadata when available or supply the documented acquisition setting. It affects range diagnostics and later normalisation, not already decoded CSV acceleration values. Observed minimum/maximum values are not a substitute for sensor limits.}
\item{GENEActiv calibrate}{Logical, default TRUE. Forwarded to GENEAread::read.bin to control upstream coefficient application. This is device-file decoding/calibration, not the within-trial dynamic VM mapping. The returned provenance records whether upstream calibration was requested. mmap_load controls memory-mapped loading, default enabled on 64-bit R, without adding an analysis filter.}
\item{SENS scale_g_per_lsb}{Acceleration scale converting signed axis counts to g; default 0.0078125 from the supported vendor binary specification. A different value requires device-format justification and changes decoded acceleration. No per-file offset or temperature correction is inferred.}
\item{GT3X precision}{Default \code{"native"} preserves original integer-sample precision through file-scale conversion for supported modern log.bin containers, using the validated read.gt3x 1.2.0 interface. \code{"legacy_3dp"} selects the earlier upstream scaled/rounded output. Precision and native recording start are recorded in metadata. Native mode does not impute gaps or extract light; choose the explicit legacy mode for those upstream options. Older activity.bin layouts require legacy mode. No lost precision is inferred from CSV or rounded input.}
\item{GT3X imputeZeroes}{Logical, default FALSE: retain the supported upstream decoder's non-imputation route. Enabling it changes the decoded treatment of missing/idle data and must be reported. add_light defaults FALSE; cleanup controls upstream extraction-file cleanup.}
\item{Axivity CWA settings}{use_ggir_fallback defaults TRUE and permits the optional GGIRread path when the fast packed-AX3 layout is unsupported. interpolationType is passed to the fallback reader (default 1). Fast and fallback implementations and their scaling/time policies are retained in metadata; the caller should inspect the selected parser.}
\item{Sensor identifiers}{sensor_vendor and sensor_model optionally annotate the sensor hardware. They do not select conversion coefficients or establish calibration traceability. Only pass arguments accepted by the detected parser.}
}
}
