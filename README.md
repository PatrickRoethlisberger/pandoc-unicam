# pandoc-unicam

A Pandoc template kit that turns a Markdown manuscript into a PDF thesis in the layout of the UNICAM LaTeX thesis template (A4, 11pt Computer Modern, twoside, title page, running headers, numbered chapters). The thesis is written in plain Markdown with YAML metadata; no LaTeX is needed in the manuscript.

## Requirements

- [Pandoc](https://pandoc.org) 3.7 or newer (tested with 3.7.0.2)
- [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref) built for the same Pandoc version (tested with 0.3.21)
- A TeX distribution with `latexmk` and `pdflatex`
- Optional: the [draw.io desktop app](https://github.com/jgraph/drawio-desktop) (CLI `drawio`) to embed `.drawio` diagrams; on headless Linux also `xvfb-run`

## Usage

The `pandoc/` directory is a Pandoc data directory. Run Pandoc from the folder of your manuscript:

```sh
pandoc --data-dir=/path/to/pandoc-unicam/pandoc -d unicam thesis.md -o thesis.pdf
```

To drop the `--data-dir` flag, run `./setup.sh` once. It finds Pandoc's user data directory (`pandoc --version` shows where it is, usually `~/.local/share/pandoc`), creates it if missing and links the kit into it:

```sh
./setup.sh
pandoc -d unicam thesis.md -o thesis.pdf
```

The script is safe to repeat. It needs a real data directory, so if you earlier symlinked the whole `pandoc/` folder to `~/.local/share/pandoc`, remove that link first. Pandoc has one data directory only; the kit's files are namespaced (`unicam`, `unicam-*`) so that other templates can be linked beside them. To uninstall, delete the links whose names start with `unicam`.

To see everything working, run `make example`; it builds `example/thesis.md` into `build/thesis.pdf`. Copy that example as the starting point for your thesis: its YAML header lists every option, and its body shows each feature below.

## Metadata

Required: `title`, `author`, `advisor`, `academic-year`.

| Key | Meaning | Default |
|---|---|---|
| `title` | Thesis title; a hard line break (`\` at the end of a line, in a `title: \|` block) gives a two-line title | – |
| `subtitle` | Printed under the title | omitted |
| `author` | One or more students, listed beneath each other. Each is a name or `{name, id}`; the ID is printed under the name | – |
| `advisor` | A name or a list of names | – |
| `coadvisor` | A name or a list; the block is omitted when absent | omitted |
| `academic-year` | e.g. `2025/2026` | – |
| `degree` | Degree line under the school, e.g. `Master's Degree in Computer Science` | omitted |
| `university`, `school` | Title page header lines | University of Camerino, School of Science and Technology |
| `logo` | Image printed above the university; relative paths are taken from where you run Pandoc. `logo: ""` removes it | Camerino crest |
| `lang` | Document language (hyphenation, babel) | `en-GB` |
| `toc`, `lof`, `lot`, `lol` | Contents, list of figures, tables, listings | all `true` |
| `toc-depth` | Levels shown in the contents | `2` |
| `index` | Print an index at the end | off |
| `table-style` | `grid` (full grid, caption below) or `plain` (Pandoc's own look) | `grid` |
| `bibliography` | Your `.bib` file; citations are formatted with APA | – |
| `csl` | Another citation style | `apa.csl` |
| `drawio-command` | Path to the draw.io CLI if it is not found automatically | auto |

Title page labels can be overridden: `student-label`, `students-label`, `advisor-label`, `advisors-label`, `coadvisor-label`, `coadvisors-label`, `student-id-label`, `academic-year-label`. Standard Pandoc LaTeX variables also work, for example `fontsize`, `geometry`, `classoption`, `linkcolor`, `citecolor`, `urlcolor`. Defaults live in `pandoc/filters/unicam-meta.lua`; anything you set in the manuscript wins.

## Writing the manuscript

| Feature | Markdown |
|---|---|
| Chapters, sections | `#`, `##`, `###` headings |
| Acknowledgements | `# Acknowledgements {.acknowledgements}` anywhere; it is moved behind the title page, unnumbered and not in the contents |
| Appendices | `# Title {.appendix}` on the first appendix; it and everything after are lettered A, B, … |
| Figure | `![Caption](images/pic.jpg){#fig:pic width=50%}` |
| Table | a pipe table followed by `: Caption {#tbl:name}` |
| Code listing | ```` ```{#lst:name .python caption="Caption"} ````; line numbers are on for every block, off with `{.no-line-numbers}` |
| References | `@fig:pic`, `@tbl:name`, `@lst:name`; for a chapter or section give the heading `{#sec:name}` and write `Chapter [-@sec:name]` |
| Citations | `[@key]` or `@key`; the bibliography is added at the end |
| Index entry | `[term]{.index}`, or `[text]{index="Main!Sub"}`; needs `index: true` |
| draw.io diagram | `![Caption](diagrams/arch.drawio){#fig:arch width=90%}` |

### draw.io diagrams

A `.drawio` image is exported to a cropped PDF beside the source (same name, `.pdf`) on every build, then used like any other figure. `{page=2}` picks a page and writes `name-page2.pdf`. If draw.io is missing or the export fails, the existing PDF beside the diagram is used with a warning; with no such PDF the build stops. Commit the exported PDFs if you build on a machine without draw.io.

### Other languages

The kit is English by default. For another language set `lang` and also the cross-reference words, because `pandoc-crossref` overrides babel's: `figureTitle`, `tableTitle`, `listingTitle`, `lofTitle`, `lotTitle`, `lolTitle`, `figPrefix`, `tblPrefix`, `lstPrefix`, `secPrefix`, `reference-section-title`.

## Things to know

- The default engine is `pdflatex`, so text and code blocks are limited to what its Unicode support covers (no Greek, arrows or emoji). For full Unicode add `--pdf-engine-opt=-pdflatex=lualatex` (or `xelatex`) to the command; both build the example, but the output has not been compared visually with the `pdflatex` one.
- Pipe tables with any source line over 72 characters get full-width, wrapped columns (Pandoc's rule). Keep lines short for natural-width tables.
- Grid tables are produced by patching Pandoc's generated LaTeX (`pandoc/filters/unicam-tables.lua`). If a table cannot be patched, a warning is printed and Pandoc's own style is kept. Hard line breaks and spanning cells inside table cells are not supported.
- The bibliography and the index appear in the contents; citation links are green and URL links magenta, as in the original template (override with `citecolor` and `urlcolor`).

## Layout of this repository

```
pandoc/                    Pandoc data directory
  defaults/unicam.yaml          defaults file (-d unicam)
  filters/unicam/               Lua filters
  csl/unicam/apa.csl            citation style
  assets/unicam/stemma.png      default logo
  templates/unicam-*.latex      LaTeX template and partials
example/                   sample thesis
setup.sh                   links the kit into Pandoc's user data directory
Makefile                   `make example`, `make clean`
```

Pandoc looks for each kind of file in a fixed folder of the data directory, which is why the kit is spread over several folders. Templates must sit directly in `templates/`; the other folders hold a `unicam/` subfolder.
