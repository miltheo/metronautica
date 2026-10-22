\name{metronautica-package}
\alias{metronautica-package}
\alias{metronautica}
\docType{package}
\title{Metronautica: Navigate wearable triaxial accelerometer signals into transparent metrology and reports.}
\description{Native wearable triaxial accelerometer parsing, signal diagnostics, clipping, static and dynamic characterisation, filtering and reporting. Developed for the wearable-accelerometer metrology research article under submission for publication; the associated analyses and data are available in WAM: \url{https://github.com/miltheo/wam}.}
\details{The package provides functions for native decoding, common-format acceleration data, signal diagnostics and selected assessments. Each function documents its input, returned quantities, units and processing settings. \code{\link{implementation-guide}} maps the workflow to the public functions.}
\section{Repositories}{Package source: \url{https://github.com/miltheo/metronautica}. WAM analyses, observations and native-recording catalogue: \url{https://github.com/miltheo/wam}. Native recording payloads are separate release attachments.}
\section{Start here}{\code{\link{getting-started}} provides a complete offline example; \code{\link{native-recording-examples}} covers stationary and ten-stage orbital-shaker recordings.}
\section{Standalone counts}{The published-filter and custom-cutoff count function \code{\link{accel_metric_agcounts}} is documented separately. The AG selector is disabled in compute_accel_summaries. GT3X parsing defaults to native precision, with an explicit legacy_3dp mode.}
\section{Scope}{\if{latex}{\out{\sloppy}} Functions calculate features and metrological outcomes for supplied recordings and selected intervals. Cohort-level inference and inter-device equivalence testing are provided by the linked WAM analyses. Calibration, filtering and analysis settings are explicit caller choices. Dynamic clipping requires explicit stepped-RPM schedule parameters; the native-recording example supplies ten six-minute stages from 50 to 500 RPM.}
\section{Workflow}{\if{latex}{\out{\sloppy}} Load a sample or supply a recording, call parse_raw_auto, inspect metadata and diagnostics, select the intended interval, then call the required metrology or feature functions. Use static_1hz_means, static_drift, static_allan and the direct accel_metric_* functions when individual outcomes are needed. Static_metrology_from_tbl and dynamic_metrology_report remain optional combined assessments.}
\seealso{\itemize{
\item{\code{\link{implementation-guide}}}
\item{\code{\link{native-recording-examples}}}
\item{\code{\link{m_load_sample_data}}}
\item{\code{\link{parse_raw_auto}}}
\item{\code{\link{qc_accel_tbl}}}
\item{\code{\link{static_metrology_from_tbl}}}
\item{\code{\link{dynamic_metrology_report}}}
\item{\code{\link{compute_accel_summaries}}}
}}
