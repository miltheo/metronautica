\name{m_load_sample_data}
\alias{m_load_sample_data}
\title{Retrieve a native recording example into a project}
\description{\if{latex}{\out{\sloppy}} Copy a local native example or explicitly download it from a configured WAM sample directory, verifying compressed and restored checksums. Measurement values are preserved.}
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
\item{base_url}{\if{latex}{\out{\sloppy}} HTTPS WAM sample directory for samples unavailable locally. Defaults to \code{metronautica.sample_base_url}. No public URL is preconfigured. A \code{file:///} directory also supports offline retrieval.}
}
\value{\if{latex}{\out{\sloppy}} The native file path, with a sample_info attribute containing source identity, analysis bounds, units and timestamp shift. A JSON sidecar contains the same information. With a dynamic reference, the path also has reference_file and reference_info attributes.}
\details{\if{latex}{\out{\sloppy}} WAM's \href{https://github.com/miltheo/wam/blob/main/samples/README.md}{sample guide} defines recording intervals, native-format boundaries, provenance and distribution terms. Clone or download WAM and set \code{sample_dir} to its included \code{samples/} folder. The installed catalogue fixes filenames and SHA-256 checksums. Downloads/decompression use temporary files; validation precedes replacement.

Apply each file's own timestamp shift and acquisition settings. Retrieval does not parse, filter or calibrate data. Installation, loading and calculations require neither WAM nor network access. See \href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#real-recording-examples}{Getting Started} for setup.}
\seealso{\href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#real-recording-examples}{Recording examples}, \code{\link{parse_raw_auto}}}
\section{Example execution}{\if{latex}{\out{\sloppy}} \code{Not run} requires external recordings. This retrieval workflow was executed locally for the guide figures.}
\examples{
\dontrun{
options(metronautica.sample_dir = "path/to/wam/samples")
path <- m_load_sample_data("LEAP", "dynamic", dest_dir = tempdir())
attr(path, "sample_info")
}
}
