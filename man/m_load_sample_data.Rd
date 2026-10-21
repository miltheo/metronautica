\name{m_load_sample_data}
\alias{m_load_sample_data}
\title{Retrieve a native study recording into a project}
\description{\if{latex}{\out{\sloppy}} Copy a local native example or explicitly download it from a configured fixed WAM release, verifying compressed and restored checksums. No measurement values are changed.}
\usage{
m_load_sample_data(device = "LEAP", type = "static", dest_dir =
    file.path(getwd(), "metronautica-samples"), overwrite = FALSE,
    sample_dir = NULL, include_reference = TRUE,
    base_url = getOption("metronautica.sample_base_url", NULL))
}
\arguments{
\item{device}{\if{latex}{\out{\sloppy}} One of LEAP, AX3, SENS or GENEActiv; matching is case-insensitive.}
\item{type}{\if{latex}{\out{\sloppy}} Either static or dynamic.}
\item{dest_dir}{\if{latex}{\out{\sloppy}} Directory in which the native recording and its provenance sidecar are created when this function is explicitly called.}
\item{overwrite}{\if{latex}{\out{\sloppy}} Allow replacement of a different existing target file, only after validation. An identical file is reused without accessing its source.}
\item{sample_dir}{\if{latex}{\out{\sloppy}} Directory containing sample_index.csv and compressed samples. Defaults to the option \code{metronautica.sample_dir}, if set. Without a local catalogue, the installed package catalogue is used.}
\item{include_reference}{\if{latex}{\out{\sloppy}} Retrieve the primary HBK reference with dynamic samples. Ignored for static samples.}
\item{base_url}{\if{latex}{\out{\sloppy}} Fixed HTTPS WAM release-asset directory, used only when a needed compressed sample is unavailable locally. Defaults to \code{metronautica.sample_base_url}. No public URL is preconfigured. A \code{file:///} directory also supports offline retrieval.}
}
\value{\if{latex}{\out{\sloppy}} The native file path, with a sample_info attribute containing source identity, analysis bounds, units and timestamp shift. A JSON sidecar contains the same information. With a dynamic reference, the path also has reference_file and reference_info attributes.}
\details{\if{latex}{\out{\sloppy}} Large native examples are distributed separately through WAM, not installed with this package. For local source checkouts, point sample_dir at WAM's samples directory. After publication, configure base_url with the fixed sample-data release asset directory. The packaged catalogue fixes filenames and SHA-256 checksums. Installation, package loading and ordinary calculations do not require WAM or network access. If a sample cannot be obtained, an informative error explains local and remote configuration. Existing identical restored files are reused offline; existing different files are protected unless overwrite is TRUE. Downloads and decompression use temporary files and validation precedes replacement.

Static files cover the analysed 24-hour stationary window, 15 August 2025 20:30 UTC to 16 August 2025 20:30 UTC. Dynamic files retain the complete first primary trial, 19 August 2025 13:18 to 14:36 UTC: ten six-minute stages from 50 to 500 RPM, including intervening two-minute adjustments. Files preserve native records, calibration coefficients and timestamps; boundary padding is retained where needed. Gzip is storage compression only. The SENS example and paired HBK reference each require their own documented +3600-second shift. This function does not parse, filter or calibrate data.}
\seealso{\code{\link{native-study-examples}}, \code{\link{parse_raw_auto}}}
\examples{
\dontrun{
# Local sibling checkout; adjust for the current project.
options(metronautica.sample_dir =
    "../wam/samples")
path <- m_load_sample_data(device = "LEAP", type = "dynamic",
                           dest_dir = tempdir())
info <- attr(path, "sample_info")
x <- parse_raw_auto(path, return = "bundle",
                    time_shift_s = info$time_shift_s,
                    full_scale_range_g = info$full_scale_range_g)
accel_meta(x)$processing$qc$ruleset
}
}

\section{Implementation}{\if{latex}{\out{\sloppy}} Implemented by \code{m_load_sample_data} in \code{R/m_sample_data.R}. See \code{\link{implementation-guide}} for the framework and manuscript mapping.}
