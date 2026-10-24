# Documentation

Edit Markdown guides, `man/*.Rd` and maintained `examples/*.R`; rebuild generated
HTML/PDF rather than editing them directly.

## Sources

| Source | Output |
|---|---|
| Root `README.md` | `index.html` |
| `man/*.Rd` | `reference.html`, PDF manual and installed R help |
| `GETTING_STARTED.md` | `getting-started.html` |
| `MEASUREMENT_DEFINITIONS.md` | `measurement-definitions.html` |
| `ACTIGRAPH_COUNTS.md` | `activity-counts.html` |
| `DEPENDENCY_LICENSING.md` | `dependency-licensing.html` |
| `../data-contract/0.1.0/SPECIFICATION.md` and the index visual | `metronautica-tibble.html` |

`data-contract/` is the versioned home of **Metronautica Tibble**. Only its four
sample columns are required; metadata and reports describe the optional pipeline
implementation. Maintain the full Markdown specification and its Word/PDF review
copies together. `man/common-data-format.Rd` provides a brief reference summary
under the `common-data-format` and `metronautica-tibble` help topics. Contract folders
are excluded from the R source package; installed help links to the repository.

To rebuild the specification's Word/PDF review copies on Windows, use Python
with `python-docx` and an installed Microsoft Word:

```powershell
./tools/build_tibble_spec.ps1 -PythonExecutable "path/to/python.exe"
```

The builder reads the maintained Markdown and applies consistent headings,
monospace code, field tables, page numbering and PDF bookmarks. Rebuild the HTML
after changing the specification text. This specification build is separate from
the R function-reference manual build below.

Getting Started is the user workflow. Its marked code blocks are embedded from
`quick_start.R` (static/dynamic) and `recording_traces.R` (traces, diagnostics,
features). Edit those scripts, not embedded copies. Linked `examples/*.R` retain
full recipes for feature settings, comparison, epoch labels and calibration.
`man/*.Rd` remains canonical for definitions and parameters.

GitHub and HTML share these Markdown sources and `assets/guides/*.svg`.
The contract visual is maintained between `GUIDE:tibble` markers in
`data-contract/README.md`; the HTML builder inserts it above the unchanged full
specification. HTML adds navigation, SVG hover/focus details and full-size links.
Rebuild after source edits; do not maintain a separate HTML narrative.

The reference contains function topics, a package overview/offline example and
technical notes. Workflow examples live in Getting Started; the function/source
map lives in the root README. Guide help names resolve to the package overview.

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

Use `--traces-only` to rebuild just the initial trace previews and example values.
Trace previews require `plotly`, `htmlwidgets` and Chrome/Chromium; set
`CHROMOTE_CHROME` when the browser is outside its standard location.

This processes the 24-hour static sample and ten-stage trial, saving previews
under `assets/examples/`. Use the recordings and catalogue in WAM's `samples/` folder.
Then rebuild HTML.

## Repository roles

`R/` defines functions; `man/` defines their reference documentation.
`inst/extdata/` installs small fixtures and the sample catalogue under `extdata/`.
`tests/` checks calculations/interfaces; `tools/` builds and validates documentation.
`validation/` contains activity-count benchmark tables.

## Browser guide

Browse the [documentation](https://miltheo.github.io/metronautica/) or open
`index.html` locally. Diagram boxes provide keyboard-accessible links and
hover details; the reference has a filterable index. Equation rendering uses
CDN-hosted KaTeX, with plain equation source available offline.

Configure GitHub Pages with **Deploy from a branch**, **main**, **/docs**.
Keep `docs/.nojekyll` to publish the prebuilt HTML. Rebuild locally before pushing;
Pages deploys the committed files. GitHub's file viewer shows HTML source.
Workflow hotspots in `tools/build_html.R` must match `assets/workflow-dark.svg`.
