# Render canonical recording examples.
# Rscript tools/render_examples.R SAMPLE_DIR [OUTPUT_DIR]
args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
if (!length(args)) stop("Supply the directory containing the sample catalogue and compressed attachments.")
sample_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
output <- if (length(args) > 1L) args[[2L]] else file.path(root, "docs/assets/examples")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(output, winslash = "/", mustWork = TRUE)
options(metronautica.sample_dir = sample_dir)
e <- new.env(parent = globalenv())
# Write sample outputs under tempdir().
local({
    before <- setwd(tempdir())
    on.exit(setwd(before), add = TRUE)
    sys.source(file.path(root, "examples/quick_start.R"), envir = e)
})
save_pair <- function(left, right, path) {
    grDevices::png(path, width = 1800, height = 700, res = 160)
    on.exit(grDevices::dev.off(), add = TRUE)
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(layout = grid::grid.layout(1L, 2L)))
    print(left, vp = grid::viewport(layout.pos.row = 1L, layout.pos.col = 1L))
    print(right, vp = grid::viewport(layout.pos.row = 1L, layout.pos.col = 2L))
}
save_pair(e$static_result$drift_plot +
    ggplot2::labs(title = "LEAP: VM drift"), e$static_result$allan_plot +
        ggplot2::labs(title = "LEAP: Allan deviation"), file.path(output, "static-characterisation.png"))
save_pair(e$dynamic_result$plots$vm_mean_vs_rpm, e$dynamic_result$plots$linearity_vs_rpm, file.path(output,
    "dynamic-characterisation.png"))
cat("Rendered full 24-hour static and ten-stage dynamic examples for LEAP.\n")

# Render the maintained comparison recipe.
local({
    before <- setwd(tempdir())
    on.exit(setwd(before), add = TRUE)
    sys.source(file.path(root, "examples", "feature_comparison.R"), envir = e)
})
ggplot2::ggsave(file.path(output, "feature-comparison.png"), e$comparison_plot, width = 12, height = 7,
    dpi = 180, bg = "white")
cat("Rendered combined feature comparison over the same ten-stage trial.\n")
