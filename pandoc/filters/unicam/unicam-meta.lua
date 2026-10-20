-- Fills in the kit's metadata defaults. Anything set in the manuscript's YAML wins.
-- Defaults live here, not in the defaults file, because options given in a
-- defaults file override the manuscript's metadata instead of yielding to it.

local script_dir = (PANDOC_SCRIPT_FILE or ''):match('^(.*)[/\\][^/\\]*$') or '.'
local default_logo = pandoc.path.normalize(script_dir .. '/../../assets/unicam/stemma.png')

local defaults = {
  -- document class and page layout of the reference template
  documentclass = 'book',
  fontsize = '11pt',
  papersize = 'a4',
  classoption = { 'twoside' },
  geometry = { 'top=3cm', 'bottom=3cm', 'inner=3.5cm', 'outer=3cm' },
  indent = true,
  lang = 'en-GB',
  -- front matter
  toc = true,
  lof = true,
  lot = true,
  lol = true,
  ['toc-depth'] = 2,
  secnumdepth = 2,
  -- title page
  university = 'University of Camerino',
  school = 'School of Science and Technology',
  logo = default_logo,
  ['student-label'] = 'Student',
  ['students-label'] = 'Students',
  ['advisor-label'] = 'Advisor',
  ['advisors-label'] = 'Advisors',
  ['coadvisor-label'] = 'Co-advisor',
  ['coadvisors-label'] = 'Co-advisors',
  ['student-id-label'] = 'Student ID',
  ['academic-year-label'] = 'Academic Year',
  -- links (hyperref colours of the reference template)
  colorlinks = true,
  linkcolor = 'black',
  citecolor = 'green',
  urlcolor = 'magenta',
  -- bibliography
  csl = 'unicam/apa.csl',
  ['link-citations'] = true,
  ['reference-section-title'] = 'Bibliography',
  -- cross-references (pandoc-crossref)
  chapters = true,
  codeBlockCaptions = true,
  figureTitle = 'Figure',
  tableTitle = 'Table',
  listingTitle = 'Listing',
  lolTitle = 'List of Listings',
  figPrefix = { 'Figure', 'Figures' },
  tblPrefix = { 'Table', 'Tables' },
  lstPrefix = { 'Listing', 'Listings' },
  secPrefix = { 'Section', 'Sections' },
}

local function names_of(list)
  local names = {}
  for _, item in ipairs(list) do
    if item.t == 'MetaMap' or (type(item) == 'table' and item.name) then
      names[#names + 1] = pandoc.utils.stringify(item.name)
    else
      names[#names + 1] = pandoc.utils.stringify(item)
    end
  end
  return names
end

-- \includegraphics runs inside LaTeX, where Pandoc's resource path does not apply, so
-- the logo is turned into an absolute path. It is emitted as raw LaTeX because a
-- metadata string would be escaped (an underscore in the path would become \_).
local function resolve_logo(meta)
  local logo = pandoc.utils.stringify(meta.logo)
  if logo == '' then
    return
  end
  if not pandoc.path.is_absolute(logo) then
    logo = pandoc.path.join({ pandoc.system.get_working_directory(), logo })
  end
  meta.logo = pandoc.MetaInlines({ pandoc.RawInline('latex', pandoc.path.normalize(logo)) })
end

function Meta(meta)
  for key, value in pairs(defaults) do
    if meta[key] == nil then
      meta[key] = value
    end
  end
  resolve_logo(meta)
  -- A single name and a list of names behave the same in the title page template,
  -- which tells them apart to choose between singular and plural labels.
  for _, key in ipairs({ 'author', 'advisor', 'coadvisor' }) do
    local value = meta[key]
    if value ~= nil and pandoc.utils.type(value) ~= 'List' then
      meta[key] = pandoc.List({ value })
    end
  end
  -- PDF metadata should carry the students' names, not their IDs.
  if meta['author-meta'] == nil and meta.author ~= nil then
    meta['author-meta'] = table.concat(names_of(meta.author), ', ')
  end
  return meta
end
