\name{metronautica-package}
\alias{metronautica-package}
\alias{metronautica}
\alias{getting-started}
\alias{implementation-guide}
\alias{native-recording-examples}
\alias{native-study-examples}
\alias{feature-comparison}
\docType{package}
\title{Metronautica: Navigate wearable triaxial accelerometer signals into transparent metrology and reports.}
\description{\if{latex}{\out{\sloppy}} Native wearable triaxial accelerometer parsing, signal diagnostics, static and dynamic characterisation, feature extraction and reporting.}
\details{\if{latex}{\out{\sloppy}} Use the linked guides for workflows and this reference for function behaviour. Filtering and calibration are explicit choices. The package returns recording-level outcomes; WAM supplies cohort inference and inter-device equivalence analyses.}
\section{Repositories}{\if{latex}{\out{\sloppy}} Developed for the wearable-accelerometer metrology research article under submission. Package source: \url{https://github.com/miltheo/metronautica}. Associated analyses, observations and native-recording catalogue: \url{https://github.com/miltheo/wam}.}
\seealso{\code{\link{metronautica-tibble}} (the sample-level data contract), \code{\link{measurement-definitions}}}

\section{Guides}{\if{latex}{\out{\sloppy}}
\href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md}{Getting Started} provides recording, characterisation, feature and calibration workflows;
\href{https://github.com/miltheo/metronautica/blob/main/README.md#function-map}{Function map} connects stages to source files;
\href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#compare-feature-pipelines}{Feature comparison} shows the shared-trial example.
The offline example below needs no external recordings or optional packages; parsing attaches primary-five diagnostics.
}
\examples{
library(metronautica)
# Load the installed recording.
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
# Defaults: ENMO and MAD.
# Select features explicitly.
features <- compute_accel_summaries(x, measures = c("ENMO", "MAD"),
    epoch_s = 5, quiet = TRUE)
# Inspect values and units.
head(features$data_wide)
features$settings$metric_units
}
