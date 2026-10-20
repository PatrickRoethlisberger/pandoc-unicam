---
# Required
title: |
  Title Of The Thesis\
  Second Line
author:                       # one or more students, listed beneath each other
  - name: First Student
    id: "000001"              # optional student ID, printed under the name
  - Second Student            # a plain name works too
advisor: Advisor Name         # a string or a list
academic-year: 2025/2026

# Optional (shown with their defaults where there is one)
coadvisor: Co-advisor Name    # block is omitted when absent
degree: Master's Degree in Computer Science
subtitle: An Optional Subtitle
# university: University of Camerino
# school: School of Science and Technology
# logo: path/to/logo.png      # default: the Camerino crest shipped with the kit
# lang: en-GB
# fontsize: 11pt              # any pandoc LaTeX variable (geometry, classoption, ...) works
# toc: true                   # contents; likewise lof, lot and lol (list of listings)
# toc-depth: 2
# table-style: grid           # or plain (Pandoc's own booktabs look)
# student-label: Student      # all title page labels can be overridden, see unicam-meta.lua
bibliography: bibliography.bib      # APA via citeproc; override with csl: file.csl
index: true                   # print an index; mark entries with [term]{.index}
---

