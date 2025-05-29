local M = {}

local config = require("config").get_config()

function M.create_cpp_file(cpp_lines, h_filename)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	local final_name = ""
	local splitted_name_var = {}
	for each in string.gmatch(cpp_filename, "[^/]+") do
		table.insert(splitted_name_var, each)
	end
	for _, part in ipairs(splitted_name_var) do
		if part == splitted_name_var[#splitted_name_var] then
			final_name = final_name .. "/" .. config.generate_cpp_file_path
		end
		final_name = final_name .. "/" .. part
	end

	cpp_filename = config.generate_cpp_file_path .. final_name
	local file = io.open(final_name, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		vim.cmd("edit " .. final_name)
		vim.lsp.buf.format()
	else
		print("Cant create file: " .. final_name)
	end
end

return M
