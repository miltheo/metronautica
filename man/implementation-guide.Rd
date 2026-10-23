\name{implementation-guide}
\alias{implementation-guide}
\title{Workflow and public function map}
\description{\if{latex}{\out{\sloppy}} Select an assessment, then use the linked function reference for its parameters, methods and return fields.}
\section{Workflow and source map}{\if{latex}{\out{\sloppy}}
\tabular{ll}{
Operation / source file \tab Entry point \cr
Parsing: R/m_parsers.R \tab \code{\link{parse_raw_auto}} \cr
Signal diagnostics: R/m_qc.R \tab \code{\link{qc_accel_tbl}} \cr
Interval selection: R/m_accel_clipper.R \tab \code{\link{clip_bundle}} \cr
Static characterisation: R/m_static.R \tab \code{\link{static_metrology_from_tbl}} \cr
Dynamic characterisation: R/m_dynamic.R \tab \code{\link{dynamic_metrology_report}} \cr
Optional calibration: R/m_dynamic.R \tab \code{\link{dm_fit_vm_calibration}} \cr
Axis filtering: R/m_filter.R \tab \code{\link{filter_accel_tbl}} \cr
Feature extraction: R/m_accel_summary_suite.R \tab \code{\link{compute_accel_summaries}} \cr
Activity counts: R/m_agcounts.R \tab \code{\link{accel_metric_agcounts}} \cr
Visualisation: R/m_plotter.R \tab \code{\link{plot_processed_metric}} \cr
Sample retrieval: R/m_sample_data.R \tab \code{\link{m_load_sample_data}} \cr
}}
\section{Definitions and examples}{\if{latex}{\out{\sloppy}}
The \code{\link{common-data-format}} defines shared inputs and epochs;
\code{\link{measurement-definitions}} defines metrology outcomes.
Feature formulas belong to their direct functions.
Start with \code{\link{getting-started}}; the
\href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#real-recording-examples}{recording guide}
provides static/dynamic code and plots.
}
\section{Assessment scope}{\if{latex}{\out{\sloppy}} Establish stationary or synchronous excitation conditions separately. Report reference, tested range, signal state, rate, epochs, filters, timing diagnostics and units. Error estimates are not a complete uncertainty budget. WAM (\url{https://github.com/miltheo/wam}) supplies cohort aggregation, trial-to-trial repeatability, activation/deadband estimation and inter-device equivalence tests.}
\references{\if{latex}{\out{\sloppy}}
Joint Committee for Guides in Metrology (2012). International vocabulary of metrology: Basic and general concepts and associated terms, JCGM 200:2012. \doi{10.59161/JCGM200-2012}.

IEEE (2018). IEEE Std 2700-2017, Standard for Sensor Performance Parameter Definitions. \doi{10.1109/IEEESTD.2018.8277147}.

IEEE (2019). IEEE Std 1293-2018, Standard Specification Format Guide and Test Procedure for Linear Single-Axis, Nongyroscopic Accelerometers. \doi{10.1109/IEEESTD.2019.8653544}.

}
\section{Input and return contracts}{\if{latex}{\out{\sloppy}}
Raw-signal helpers accept four-column acceleration tables or data/full bundles. Unwrapping does not select, sort or repair samples. Table metadata takes precedence over top-level meta.
\describe{
\item{Container operations}{static_clip returns a table; clip_dynamic_stages creates a stage bundle. Generic clipping, QC, filtering and calibration preserve their documented input form.}
\item{Stage bundles}{filter_accel_tbl and clip_bundle change only full; existing stages remain unchanged. Perform these operations before constructing stages. Calibration application processes full and stages.}
\item{Derived inputs}{static_drift and static_offset_vm_5min require one-second means; Allan-minimum/plot helpers require an Allan table; allan_nonoverlap requires a numeric axis series. Dynamic reporting/fitting requires corresponding named stage bundles; m_dynamic_response also accepts numeric VM vectors. Parsers/loaders take paths or sample selectors.}
}
Calculation helpers return derived results rather than the original container.
}
