local M = {}

local process_cpp = require("generationfile.process_cpp")
local insert_file_structure = require("generationfile.insert_file_structure")
local file_utils = require("utils.file_utils")

function M.generate_cpp_file()
	local file_structure = insert_file_structure.get_class_structure("class")
	if #file_structure.classes <= 0 then
		print("No classes in the file")
		return
	end
	local h_filename = vim.api.nvim_buf_get_name(0)
	local cpp_lines = process_cpp.process_file_structure(file_structure)
	file_utils.create_cpp_file(cpp_lines, h_filename)
end
return M
