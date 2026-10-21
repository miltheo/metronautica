# For sibling source checkouts; adjust this path for your project.
options(metronautica.sample_dir =
    "../wam/samples")
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
accel <- parse_raw_auto(path, return = "bundle", time_shift_s = info$time_shift_s,
                        full_scale_range_g = info$full_scale_range_g)
accel_meta(accel)$processing$qc
plot_accel_clip(accel, include_vm = TRUE)
enmo <- compute_accel_summaries(accel, measures = "ENMO", epoch_s = 5)
plot_processed_metric(enmo, "ENMO")
