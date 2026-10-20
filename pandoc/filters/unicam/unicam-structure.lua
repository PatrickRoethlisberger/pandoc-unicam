-- Handles the two kinds of top-level parts that are not ordinary chapters:
--   # Acknowledgements {.acknowledgements}   moved behind the title page, unnumbered, not in the TOC
--   # Appendix title {.appendix}             the first one switches to lettered appendices

local function has_class(el, class)
  for _, c in ipairs(el.classes) do
    if c == class then return true end
  end
  return false
end

function Pandoc(doc)
  local body = pandoc.List()
  local acknowledgements = pandoc.List()
  local collecting_level = nil
  local appendix_started = false

  for _, block in ipairs(doc.blocks) do
    if block.t == 'Header' then
      if collecting_level and block.level <= collecting_level then
        collecting_level = nil
      end
      if not collecting_level and has_class(block, 'acknowledgements') then
        collecting_level = block.level
        block.classes:insert('unnumbered')
        block.classes:insert('unlisted')
      elseif has_class(block, 'appendix') and not appendix_started then
        appendix_started = true
        body:insert(pandoc.RawBlock('latex', '\\appendix'))
      end
    end
    if collecting_level then
      acknowledgements:insert(block)
    else
      body:insert(block)
    end
  end

  if #acknowledgements > 0 then
    doc.meta['unicam-acknowledgements'] = pandoc.MetaBlocks(acknowledgements)
  end
  doc.blocks = body
  return doc
end
