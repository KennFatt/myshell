-- Wrap table cell contents in a clamp container for 2-line ellipsis.
-- Produces <td><div class="td-clamp">...</div></td> so modern CSS
-- line-clamp can apply without changing the table-cell display type.
-- Note: pandoc 3.x Lua does not traverse Cell directly, so walk Table.
local function wrap_rows(rows)
	if rows == nil then
		return
	end
	for _, row in ipairs(rows) do
		if row.cells ~= nil then
			for _, cell in ipairs(row.cells) do
				if cell.contents ~= nil and #cell.contents > 0 then
					local already = false
					if #cell.contents == 1 and cell.contents[1].t == "Div" then
						for _, class in ipairs(cell.contents[1].classes) do
							if class == "td-clamp" then
								already = true
								break
							end
						end
					end
					if not already then
						cell.contents = { pandoc.Div(cell.contents, pandoc.Attr("", { "td-clamp" }, {})) }
					end
				end
			end
		end
	end
end

function Table(tbl)
	if tbl.head ~= nil then
		wrap_rows(tbl.head.rows)
	end
	for _, body in ipairs(tbl.bodies or {}) do
		wrap_rows(body.body)
		wrap_rows(body.head)
	end
	if tbl.foot ~= nil then
		wrap_rows(tbl.foot.rows)
	end
	-- div.table-wrap is the box that scrolls sideways (a table box cannot),
	-- which keeps the page itself from scrolling when a table is wide.
	return pandoc.Div({ tbl }, pandoc.Attr("", { "table-wrap" }, {}))
end
