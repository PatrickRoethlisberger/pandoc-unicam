-- Number the lines of every code block, as the reference template does. Adding the
-- numberLines class also routes blocks without a language through Pandoc's
-- highlighter, so they get the same grey box as highlighted ones.
-- Opt out per block with {.no-line-numbers}.

function CodeBlock(block)
  if block.classes:includes('no-line-numbers') then
    return nil
  end
  if not block.classes:includes('numberLines') then
    block.classes:insert('numberLines')
  end
  return block
end
