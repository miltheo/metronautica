# Documentation

Edit Markdown guides, `man/*.Rd` and maintained `examples/*.R`; rebuild generated
HTML/PDF rather than editing them directly.

## Sources

| Source | Output |
|---|---|
| Root `README.md` | `index.html` |
| `man/*.Rd` | `reference.html`, PDF manual and installed R help |
| `GETTING_STARTED.md` | `getting-started.html` |
| `REAL_DATA_EXAMPLES.md` | `recording-examples.html` |
| `MEASUREMENT_DEFINITIONS.md` | `measurement-definitions.html` |
| `ACTIGRAPH_COUNTS.md` | `activity-counts.html` |
| `DEPENDENCY_LICENSING.md` | `dependency-licensing.html` |

The HTML builder embeds maintained example scripts into marked guide blocks.
`quick_start.R` supplies static/dynamic examples; the other recipes cover offline
features, settings, comparison and calibration. Edit the scripts, not embedded copies.

## Build and check

From the repository root:

```sh
Rscript tools/build_html.R
Rscript tools/build_manual.R
Rscript tools/validate.R
```

HTML requires R >= 4.5 (`tools::pkg2HTML()`), `commonmark` and `V8`.
PDF generation requires a working R/LaTeX documentation toolchain.
These are build tools, not package runtime dependencies.

After installing the package, regenerate recording plots only when needed:

```sh
Rscript tools/render_examples.R "path/to/wam/samples"
```

This processes the 24-hour static sample and ten-stage trial, saving previews
under `assets/examples/`. Compressed attachments and their catalogue must be local.
Then rebuild HTML.

## Repository roles

`R/` defines functions; `man/` defines their reference documentation.
`inst/extdata/` installs small fixtures and the sample catalogue under `extdata/`.
`tests/` checks calculations/interfaces; `tools/` builds and validates documentation.
`validation/` contains activity-count benchmark tables.

## Browser guide

Open `index.html` locally. Diagram boxes provide keyboard-accessible links and
hover details; the reference has a filterable index. Equation rendering uses
CDN-hosted KaTeX, with plain equation source available offline.

GitHub's file viewer shows HTML source. GitHub Pages remains on hold; builds do
not enable hosting. Workflow hotspots are maintained in `tools/build_html.R` and
must match `assets/workflow-dark.svg` if the diagram changes.
