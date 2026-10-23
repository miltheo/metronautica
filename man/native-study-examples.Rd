\name{native-recording-examples}
\alias{native-recording-examples}
\alias{native-study-examples}
\title{Static and dynamic recording examples}
\description{\if{latex}{\out{\sloppy}} Worked examples using separately distributed native recordings.}
\details{\if{latex}{\out{\sloppy}} Configure \code{metronautica.sample_dir} with the catalogue and attachments from the \href{https://github.com/miltheo/wam/blob/main/samples/README.md}{WAM sample guide}.

The \href{https://github.com/miltheo/metronautica/blob/main/docs/GETTING_STARTED.md#real-recording-examples}{worked guide} demonstrates static characterisation and ten-stage dynamic assessment against the HBK reference, including code and plots. Apply each file's supplied timestamp shift and measurement span. Full static parsing can require several minutes and substantial memory.

The complete runnable script is \href{https://github.com/miltheo/metronautica/blob/main/examples/quick_start.R}{quick_start.R}. These one-unit examples demonstrate calculations, without establishing between-device equivalence or behavioural validity.}
\seealso{\code{\link{m_load_sample_data}}, \code{\link{static_metrology_from_tbl}}, \code{\link{dynamic_metrology_report}}}
