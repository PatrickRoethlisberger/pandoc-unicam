-- Embeds draw.io diagrams. An image whose path ends in .drawio is exported to a cropped
-- PDF beside the source (same name, .pdf) on every run, and the image then points at
-- that PDF, so captions, numbering and cross-references work as for any other figure:
--   ![Architecture](diagrams/arch.drawio){#fig:arch width=80%}
--   ![Second page](diagrams/arch.drawio){page=2}      -> diagrams/arch-page2.pdf
-- The export needs the draw.io desktop CLI. When it is missing or fails, an existing
-- PDF beside the diagram is used instead (with a warning); without one the build stops.
-- `drawio-command: /path/to/drawio` in the metadata names the CLI explicitly.

local function log(msg)
  io.stderr:write('[unicam-drawio] ' .. msg .. '\n')
end

local function fail(msg)
  log('ERROR: ' .. msg)
  error(msg, 0)
end

local function exists(path)
  local f = io.open(path, 'rb')
  if f then f:close() end
  return f ~= nil
end

local command_override

-- The draw.io executable: the metadata override if given (and only that), otherwise
-- PATH, then the macOS application bundle.
local function find_command()
  local candidates = { 'drawio', 'draw.io', '/Applications/draw.io.app/Contents/MacOS/draw.io' }
  if command_override then candidates = { command_override } end
  for _, candidate in ipairs(candidates) do
    if candidate:find('/', 1, true) then
      if exists(candidate) then return candidate end
    else
      local ok = pcall(pandoc.pipe, 'which', { candidate }, '')
      if ok then return candidate end
    end
  end
end

-- Locates the diagram through the resource path, like Pandoc does for images.
local function find_source(src)
  if pandoc.path.is_absolute(src) then
    return exists(src) and src or nil
  end
  local dirs = PANDOC_STATE.resource_path
  if not dirs or #dirs == 0 then dirs = { '.' } end
  for _, dir in ipairs(dirs) do
    local candidate = pandoc.path.join({ dir, src })
    if exists(candidate) then return candidate end
  end
end

-- Runs the CLI with its stderr folded into stdout: Electron prints harmless noise on
-- success, and on failure the real message then ends up in the error we report.
local function run(command, args)
  if pandoc.system.os == 'mingw32' then
    return pcall(pandoc.pipe, command, args, '')
  end
  local wrapped = { '-c', 'exec "$@" 2>&1', 'sh', command }
  for _, arg in ipairs(args) do wrapped[#wrapped + 1] = arg end
  return pcall(pandoc.pipe, 'sh', wrapped, '')
end

-- draw.io numbered pages from 0 on the command line until v27.0.2, and from 1 since.
local function page_index(command, page)
  local ok, out = run(command, { '--version' })
  local major, minor, patch = tostring(ok and out or ''):match('(%d+)%.(%d+)%.(%d+)')
  if major then
    major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
    if major < 27 or (major == 27 and minor == 0 and patch < 2) then
      return page - 1
    end
  end
  return page
end

local function export(command, source, target, page)
  local args = { '-x', '-f', 'pdf', '--crop', '-o', target,
                 '-p', tostring(page_index(command, page or 1)), source }
  if pandoc.system.os == 'linux' then
    -- headless Linux (CI) has no display, and root cannot run Electron's sandbox
    args[#args + 1] = '--no-sandbox'
    if not os.getenv('DISPLAY') and pcall(pandoc.pipe, 'which', { 'xvfb-run' }, '') then
      table.insert(args, 1, command)
      table.insert(args, 1, '-a')
      command = 'xvfb-run'
    end
  end
  return run(command, args)
end

local cache = {}

local function render(src, page)
  local key = src .. '#' .. tostring(page)
  if cache[key] then return cache[key] end

  local source = find_source(src)
  if not source then
    fail('diagram not found: ' .. src)
  end
  local base = src:gsub('%.[^./\\]+$', '')
  local suffix = (page and page > 1) and ('-page' .. page) or ''
  local target_src = base .. suffix .. '.pdf'
  local target = source:gsub('%.[^./\\]+$', '') .. suffix .. '.pdf'

  local command = find_command()
  local reason
  if not command then
    reason = 'the draw.io CLI was not found (install draw.io desktop, or set drawio-command)'
  else
    -- Export to a temporary file first so a failed run never clobbers the fallback PDF.
    -- draw.io reports some errors (e.g. a page that does not exist) with exit code 0,
    -- hence the check that the output actually appeared.
    local tmp = target .. '.tmp'
    os.remove(tmp)
    local ok, err = export(command, source, tmp, page)
    if ok and exists(tmp) then
      os.remove(target)
      assert(os.rename(tmp, target))
      cache[key] = target_src
      return target_src
    end
    os.remove(tmp)
    reason = 'exporting ' .. source .. ' failed: ' .. tostring(err)
  end

  if exists(target) then
    log('WARNING: ' .. reason .. '; using the existing ' .. target)
    cache[key] = target_src
    return target_src
  end
  fail(reason .. ', and there is no fallback PDF at ' .. target)
end

local function read_meta(meta)
  if meta['drawio-command'] then
    command_override = pandoc.utils.stringify(meta['drawio-command'])
  end
end

local function image(img)
  if not img.src:lower():match('%.drawio$') and not img.src:lower():match('%.dio$') then
    return nil
  end
  local page = tonumber(img.attributes['page'])
  img.attributes['page'] = nil
  img.src = render(img.src, page)
  return img
end

-- Meta is visited first, so the command override is known by the time images are.
return { { Meta = read_meta }, { Image = image } }
