local ts_query = require("nvim-treesitter.query")
local process_cpp = require("process_cpp")
local insert_file_structure = require("insert_file_structure")
local file_utils = require("file_utils")

local M = {}

function M.generate_method_implementation()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()

	local hpp_file_structure = insert_file_structure.get_class_structure("class")

	local class_with_method_to_implement = {
		name = "",
		methods = {},
	}

	local vstart = vim.fn.getpos(".")
	local line_selected = vstart[2] - 1
	local result = ts_query.get_query("cpp", "class")
	for id, node in result:iter_captures(root, bufnr, line_selected, line_selected + 1) do
		local capture_name = result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)
		insert_file_structure.insert_method(class_with_method_to_implement, capture_name, capture_value, node:range())
	end

	class_with_method_to_implement.name = insert_file_structure.get_class_name_from_method(
		hpp_file_structure.classes,
		class_with_method_to_implement.methods[#class_with_method_to_implement.methods]
	)

	vim.cmd("edit " .. file_utils.generate_cpp_file_path(vim.api.nvim_buf_get_name(0)))

	local cpp_file_structure = insert_file_structure.get_class_structure("implementation_file")

	if insert_file_structure.is_alredy_implemented(cpp_file_structure, class_with_method_to_implement) == true then
		print(
			"Cant implement "
				.. class_with_method_to_implement.methods[#class_with_method_to_implement.methods].name
				.. " alredy implemented"
		)
	else
		local cpp_lines = {}
		process_cpp.process_methods(class_with_method_to_implement, cpp_lines)

		-- TODO: Si la clase no tiene ningun metodo implementado, no sabe donde tiene que poner la nueva implementacion
		-- pensar como lo puedo hacer
		-- Podria utilizar el constructor, pero si no tiene constructor como lo pueod hacer??
		local methods = cpp_file_structure.classes[class_with_method_to_implement.name].methods
		vim.api.nvim_buf_set_lines(
			vim.api.nvim_get_current_buf(),
			cpp_file_structure.classes[class_with_method_to_implement.name].methods[#methods].endline,
			cpp_file_structure.classes[class_with_method_to_implement.name].methods[#methods].endline,
			false,
			cpp_lines
		)
	end
end

return M
