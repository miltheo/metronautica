\name{accel_meta}
\alias{accel_meta}
\title{Read acceleration metadata}
\description{\if{latex}{\out{\sloppy}} Read attached metadata without modifying acceleration.}
\usage{
accel_meta(x)
}
\arguments{
\item{x}{\if{latex}{\out{\sloppy}} Acceleration table or parser/clip bundle; see \code{\link{common-data-format}}.}
}
\value{\if{latex}{\out{\sloppy}} The \code{meta} attribute, normally a list; \code{NULL} if absent.}
\seealso{\code{\link{as_accel_tbl}}, \code{\link{common-data-format}}}
\examples{
path <- system.file("extdata", "example_motion.csv",
    package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)
accel_meta(x)$acquisition
}
