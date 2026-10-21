\name{metronautica-package}
\alias{metronautica-package}
\alias{metronautica}
\docType{package}
\title{Wearable Accelerometer Parsing, Diagnostics and Metrology}
\description{\if{latex}{\out{\sloppy}} Direct R functions for native decoding, primary-five signal diagnostics, clipping, stationary and dynamic characterisation, filtering and time-domain acceleration features.}
\details{\if{latex}{\out{\sloppy}} All engine functions reside directly in ten R/m_*.R files. Loading the package makes the functions available. Functions returning tables and bundles document their container and units. The companion WAM repository distributes native samples as release attachments from one laboratory unit each of LEAP, AX3, SENS and GENEActiv. The package retains a small catalogue and offline fixtures. Configure a local sample directory or fixed release-asset URL and use m_load_sample_data to retrieve one sample into a project; dynamic examples include the primary HBK reference by default. These are controlled laboratory recordings, not human behavioural validation data.}
\section{Start here}{\code{\link{getting-started}} provides a complete offline example; \code{\link{native-study-examples}} extends it to laboratory recordings.}
\section{Standalone counts}{The published-filter and custom-cutoff count function \code{\link{accel_metric_agcounts}} is documented separately. The AG selector is disabled in compute_accel_summaries. GT3X parsing defaults to native precision, with an explicit legacy_3dp mode.}
\section{Scope}{\if{latex}{\out{\sloppy}} Functions calculate features and metrological outcomes for supplied recordings and selected intervals. The package does not append study master sheets, orchestrate repeated study trials, automatically compare native/calibrated pipelines or perform cohort-level inference. Calibration, filtering and analysis settings are explicit caller choices. Dynamic clipping requires explicit stepped-RPM schedule parameters; the native example supplies the manuscript schedule.}
\section{Workflow}{\if{latex}{\out{\sloppy}} Load a sample or supply a recording, call parse_raw_auto, inspect metadata and diagnostics, select the intended interval, then call the required metrology or feature functions. Use static_1hz_means, static_drift, static_allan and the direct accel_metric_* functions when individual outcomes are needed. Static_metrology_from_tbl and dynamic_metrology_report remain optional combined assessments.}
\seealso{\itemize{
\item{\code{\link{implementation-guide}}}
\item{\code{\link{native-study-examples}}}
\item{\code{\link{m_load_sample_data}}}
\item{\code{\link{parse_raw_auto}}}
\item{\code{\link{qc_accel_tbl}}}
\item{\code{\link{static_metrology_from_tbl}}}
\item{\code{\link{dynamic_metrology_report}}}
\item{\code{\link{compute_accel_summaries}}}
}}
