-- Index entries. A span marked `.index` puts its own text in the index:
--   [WebSocket]{.index}
-- A span with an `index` attribute files the text under a different entry:
--   [Scrooge]{index="McDuck, Scrooge"}   or   [Scrooge]{index="McDuck!Scrooge"} (sub-entry)
-- The index itself is printed when the manuscript sets `index: true`.

function Span(span)
  local entry = span.attributes['index']
  if not entry and not span.classes:includes('index') then
    return nil
  end
  if not entry then
    entry = pandoc.utils.stringify(span.content)
  end
  local content = pandoc.List(span.content)
  content:insert(pandoc.RawInline('latex', '\\index{' .. entry .. '}'))
  return content
end
