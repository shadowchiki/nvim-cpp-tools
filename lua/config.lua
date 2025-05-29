local M = {}

M.config = {
	generate_cpp_file_path = "",
}

function M.setup(user_config)
	if user_config ~= nil then
		if user_config.generate_cpp_file_path ~= nil then
			M.config.generate_cpp_file_path = user_config.generate_cpp_file_path
		end
	end
end

function M.get_config()
	return M.config
end

return M
