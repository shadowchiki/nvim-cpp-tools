local M = {}

local config = require("config").get_config()

function M.generate_include_file_path(h_filename)
	local name = M.generate_file_path(h_filename)

	local splitted_name_var = {}
	for each in string.gmatch(name, "[^/]+") do
		table.insert(splitted_name_var, each)
	end
	local split_config = string.gmatch(config.generate_cpp_file_path, "[^/]+")
	local fist_position_on_iterator = split_config()
	local position_config = -1
	for position, each in ipairs(splitted_name_var) do
		if each == fist_position_on_iterator then
			position_config = position
			break
		end
	end
	local final_name = ""
	for position, each in ipairs(splitted_name_var) do
		if position >= position_config then
			if final_name == "" then
				final_name = each
			else
				final_name = final_name .. "/" .. each
			end
		end
	end
	final_name = string.gsub(final_name, config.generate_cpp_file_path, config.origin_hpp_file_path)
	return final_name
end

function M.generate_file_path(h_filename)
	local splitted_name_var = {}
	local final_name = ""
	for each in string.gmatch(h_filename, "[^/]+") do
		table.insert(splitted_name_var, each)
	end
	for _, part in ipairs(splitted_name_var) do
		if part == splitted_name_var[#splitted_name_var] then
			final_name = final_name .. "/" .. config.generate_cpp_file_path
		end
		final_name = final_name .. "/" .. part
	end
	return final_name
end

function M.generate_cpp_file_path(h_filename)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	return M.generate_file_path(cpp_filename)
end

function M.create_cpp_file(cpp_lines, h_filename)
	local final_name = M.generate_cpp_file_path(h_filename)
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
