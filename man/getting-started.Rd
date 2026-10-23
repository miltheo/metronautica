\name{getting-started}
\alias{getting-started}
\title{Start with an offline acceleration workflow}
\description{\if{latex}{\out{\sloppy}} Parse an installed example, inspect QC and compute epoch features offline.}
\details{\if{latex}{\out{\sloppy}} The installed fixture requires no external recordings or optional packages. Parsing attaches primary-five QC by default. \href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md}{Getting started} provides the complete workflow, native-recording examples and plot previews. \href{https://github.com/miltheo/metronautica/blob/main/docs/REAL_DATA_EXAMPLES.md#epoch-labels}{Epoch labels} explains mixed-feature timestamp joins.}
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
\seealso{\code{\link{common-data-format}}, \code{\link{compute_accel_summaries}}, \code{\link{native-recording-examples}}}
