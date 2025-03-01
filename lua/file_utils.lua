local M = {}

function M.create_cpp_file(cpp_lines, h_filename)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	local file = io.open(cpp_filename, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		vim.cmd("edit " .. cpp_filename)
		vim.lsp.buf.format()
	else
		print("Cant create file: " .. cpp_filename)
	end
end

return M
