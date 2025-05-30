local M = {}

local config = require("config.config").get_config()

function M.split_file_path(h_filename)
	local splitted_name = {}
	for each in string.gmatch(h_filename, "[^/]+") do
		table.insert(splitted_name, each)
	end
	return splitted_name
end

function M.get_position_off_the_configuration(splitted_name)
	local split_config = string.gmatch(config.generate_cpp_file_path, "[^/]+")
	local fist_position_on_iterator = split_config()
	local position_config = -1
	for position, each in ipairs(splitted_name) do
		if each == fist_position_on_iterator then
			position_config = position
			break
		end
	end
	return position_config
end

function M.construct_include_path(splitted_name, position_config)
	local final_name = ""
	for position, each in ipairs(splitted_name) do
		if position >= position_config then
			if final_name == "" then
				final_name = each
			else
				final_name = final_name .. "/" .. each
			end
		end
	end
	return final_name
end

function M.generate_include_file_path(h_filename)
	local final_name = ""
	if
		config.generate_cpp_file_path ~= nil and config.generate_cpp_file_path ~= ""
		or config.origin_hpp_file_path ~= nil and config.origin_hpp_file_path ~= ""
	then
		local name = M.generate_file_path(h_filename)
		local splitted_name = M.split_file_path(name)
		local position_config = M.get_position_off_the_configuration(splitted_name)
		final_name = M.construct_include_path(splitted_name, position_config)
		final_name = string.gsub(final_name, config.generate_cpp_file_path, config.origin_hpp_file_path)
	else
		final_name = h_filename:match("([^/]+)$")
	end
	return final_name
end

function M.generate_file_path(h_filename)
	local final_name = ""
	local splitted_name = M.split_file_path(h_filename)
	for _, part in ipairs(splitted_name) do
		if part == splitted_name[#splitted_name] then
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
