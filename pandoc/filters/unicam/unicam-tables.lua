-- Gives tables the look of the reference template: a full grid of rules and the
-- caption below the table. Pandoc has no option for this, so the filter lets
-- Pandoc's LaTeX writer produce each longtable and then patches the result.
-- Switch off with `table-style: plain` in the manuscript metadata. If a table
-- cannot be patched (unexpected writer output) it is left as Pandoc wrote it.

local grid = true

function Meta(meta)
  if meta['table-style'] and pandoc.utils.stringify(meta['table-style']) == 'plain' then
    grid = false
  end
end

-- Index of the brace that closes the one opened at position `open`.
local function closing_brace(s, open)
  local depth = 0
  for i = open, #s do
    local c = s:sub(i, i)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then return i end
    end
  end
end

-- Splits a longtable column specification such as `@{}l>{\raggedright}p{..}r@{}`
-- into its columns.
local function split_columns(spec)
  spec = spec:gsub('%s+', ' '):gsub('^%s*@{}', ''):gsub('@{}%s*$', '')
  local columns, i = {}, 1
  while i <= #spec do
    local c = spec:sub(i, i)
    if c == ' ' then
      i = i + 1
    elseif c:match('[lcr]') then
      columns[#columns + 1] = c
      i = i + 1
    elseif c == '>' then
      local close = closing_brace(spec, i + 1)
      local p_open = close and spec:find('p{', close + 1, true)
      local p_close = p_open and closing_brace(spec, p_open + 1)
      if not p_close then return nil end
      columns[#columns + 1] = spec:sub(i, p_close)
      i = p_close + 1
    else
      return nil
    end
  end
  return columns
end

local function patch(tex)
  local spec_open = tex:find('\\begin{longtable}[]{', 1, true)
  if not spec_open then return nil end
  local brace = spec_open + #'\\begin{longtable}[]'
  local spec_close = closing_brace(tex, brace)
  local columns = split_columns(tex:sub(brace + 1, spec_close - 1))
  if not columns or #columns == 0 then return nil end
  local head, rest = tex:sub(1, brace - 1), tex:sub(spec_close + 1)

  -- the caption sits on the first line(s) of the table; move it below
  local caption
  local cap_start = rest:find('^\n\\caption{')
  if cap_start then
    local close = closing_brace(rest, #'\n\\caption' + 1)
    local tail = rest:match('^\\tabularnewline', close + 1)
    if close and tail then
      caption = rest:sub(2, close) .. '\\tabularnewline'
      rest = rest:sub(close + #'\\tabularnewline' + 1)
    end
  end

  -- widths computed by Pandoc assume zero padding at both outer edges and no rules
  local ncols = #columns
  for i, column in ipairs(columns) do
    columns[i] = column:gsub('%(\\linewidth %- (%d+)\\tabcolsep%)', function(n)
      return string.format('(\\linewidth - %d\\tabcolsep - %d\\arrayrulewidth)',
        tonumber(n) + 2, ncols + 1)
    end)
  end

  rest = rest:gsub('\\toprule\\noalign{}', '\\hline')
  rest = rest:gsub('\\midrule\\noalign{}', '\\hline')
  rest = rest:gsub('\\bottomrule\\noalign{}\n', '')
  -- every body row gets a rule below it
  local first, last = rest:find('\\endlastfoot\n', 1, true)
  if not first then return nil end
  local body = rest:sub(last + 1):gsub('(%s)\\\\\n', '%1\\\\ \\hline\n')
  rest = rest:sub(1, last) .. body
  if caption then
    rest = rest:gsub('\n\\end{longtable}%s*$', '\n' .. caption:gsub('%%', '%%%%') .. '\n\\end{longtable}')
  end

  return head .. '{|' .. table.concat(columns, '|') .. '|}' .. rest
end

function Table(tbl)
  if not grid or not FORMAT:match('latex') then return nil end
  local tex = pandoc.write(pandoc.Pandoc({ tbl }), 'latex')
  local patched = patch(tex)
  if not patched then
    io.stderr:write('[unicam-tables] could not apply the grid style to a table; keeping Pandoc\'s own\n')
    return nil
  end
  return pandoc.RawBlock('latex', patched)
end

-- Filters run Meta before Table, so the switch is known by the time tables are visited.
return { { Meta = Meta }, { Table = Table } }
