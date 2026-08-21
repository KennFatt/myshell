-- Lightweight fallback because Pandoc does not recognize TSX or JSONC.
-- Highlighting is approximate: proper support requires custom Skylighting
-- definitions for TypeScript + JSX and JSON + comments.
local aliases = {
	tsx = "jsx",
	jsonc = "javascript",
}

function CodeBlock(block)
	for _, class in ipairs(block.classes) do
		local alias = aliases[class]
		if alias then
			table.insert(block.classes, 1, alias)
			return block
		end
	end

	return block
end
