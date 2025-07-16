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
	local splitted_final_name = M.split_file_path(final_name)
	for i = 1, #splitted_final_name - 3 do
		final_name = "../" .. final_name
	end
	print(final_name)
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
	local origin_path_splitted = M.split_file_path(config.origin_hpp_file_path)
	for _, part in ipairs(splitted_name) do
		if part == origin_path_splitted[#origin_path_splitted] then
			final_name = final_name .. "/" .. config.generate_cpp_file_path
		else
			final_name = final_name .. "/" .. part
		end
	end
	return final_name
end

function M.generate_cpp_file_path(h_filename)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	if config.generate_cpp_file_path == "" or config.origin_hpp_file_path == "" then
		return cpp_filename
	end
	local final_name = M.generate_file_path(cpp_filename)
	local origin_path_splitted = M.split_file_path(config.origin_hpp_file_path)
	local generate_path_splitted = M.split_file_path(config.generate_cpp_file_path)
	final_name = string.gsub(
		cpp_filename,
		origin_path_splitted[#origin_path_splitted],
		generate_path_splitted[#generate_path_splitted]
	)
	return final_name
end

function M.create_cpp_file(cpp_lines, h_filename)
	local final_name = M.generate_cpp_file_path(h_filename)
	local file = io.open(final_name, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		pcall(vim.cmd("edit " .. final_name))
		local mason_clang_format = vim.fn.stdpath("data") .. "/mason/bin/clang-format"
		os.execute(string.format("%s -i %q", mason_clang_format, final_name))
	else
		vim.notify("Cant create file: " .. final_name, vim.log.levels.ERROR)
	end
end

return M
