Installed offline data and sample catalogue.

example_motion.csv: synthetic continuous acceleration for runnable help examples.
leap_reference.agsd: 16 non-contiguous LEAP records for decoder and loader tests.
leap_reference.rds: expected rounded vendor values, timestamps and provenance for
those records. These are test fixtures, not a complete static or dynamic trial.
native/sample_index.csv: external recording catalogue used by m_load_sample_data().

Keep these files in inst/extdata in the source package. R installs them as extdata
at the package root, accessible through system.file("extdata", package="metronautica").
Complete analysis-window samples are distributed separately through WAM.
