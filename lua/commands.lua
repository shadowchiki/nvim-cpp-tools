local ts_query = require("nvim-treesitter.query")
local process_cpp = require("process_cpp")
local insert_file_structure = require("insert_file_structure")

local M = {}

function M.generate_method_implementation()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()

	local vstart = vim.fn.getpos(".")
	local line_selected = vstart[2] - 1

	local hpp_file_structure = insert_file_structure.get_class_structure()

	local class = {
		name = "",
		methods = {},
	}

	local result = ts_query.get_query("cpp", "class")
	for id, node in result:iter_captures(root, bufnr, line_selected, line_selected + 1) do
		local capture_name = result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)
		if capture_name == "methodType" then
			class.methods[#class.methods].type = capture_value
		end

		if capture_name == "methodName" then
			class.methods[#class.methods].name = capture_value
		end

		if capture_name == "methodLine" then
			table.insert(class.methods, { type = "", name = "", line = node:range() + 1 })
		end
	end

	class.name =
		insert_file_structure.get_class_name_from_method(hpp_file_structure.classes, class.methods[#class.methods])

	local h_filename = vim.api.nvim_buf_get_name(0)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	vim.cmd("edit " .. cpp_filename)
	bufnr = vim.api.nvim_get_current_buf()
	parser = vim.treesitter.get_parser(bufnr)
	tree = parser:parse()[1]
	root = tree:root()

	local file_structure_cpp = {
		classes = {},
	}

	local cpp_result = ts_query.get_query("cpp", "implementation_file")
	local actual_class = ""
	for id, node in cpp_result:iter_captures(root, bufnr) do
		local capture_name = cpp_result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)
		local start_line, start_col, end_line, end_col = node:range()

		if capture_name == "className" then
			if not file_structure_cpp.classes[capture_value] then
				file_structure_cpp.classes[capture_value] = {
					name = capture_value,
					methods = {},
				}
			end
			actual_class = capture_value
		end
		if capture_name == "methodType" and file_structure_cpp ~= nil then
			if file_structure_cpp then
				table.insert(
					file_structure_cpp.classes[actual_class].methods,
					{ type = capture_value, name = "", endline = 0 }
				)
			end
		end

		if capture_name == "methodName" and file_structure_cpp ~= nil then
			if file_structure_cpp then
				file_structure_cpp.classes[actual_class].methods[#file_structure_cpp.classes[actual_class].methods].name =
					capture_value
			end
		end
		if capture_name == "methodParameters" and file_structure_cpp ~= nil then
			if file_structure_cpp then
				local methodName =
					file_structure_cpp.classes[actual_class].methods[#file_structure_cpp.classes[actual_class].methods].name
				methodName = methodName .. capture_value
			end
		end
		if capture_name == "completeFunction" and file_structure_cpp ~= nil then
			if file_structure_cpp then
				file_structure_cpp.classes[actual_class].methods[#file_structure_cpp.classes[actual_class].methods].endline = end_line
					+ 1
			end
		end
	end
	local cpp_lines = {}
	process_cpp.process_methods(class, cpp_lines)

	-- TODO: Si la clase no tiene ningun metodo implementado, no sabe donde tiene que poner la nueva implementacion
	-- pensar como lo puedo hacer
	-- Podria utilizar el constructor, pero si no tiene constructor como lo pueod hacer??
	local methods = file_structure_cpp.classes[class.name].methods
	vim.api.nvim_buf_set_lines(
		bufnr,
		file_structure_cpp.classes[class.name].methods[#methods].endline,
		file_structure_cpp.classes[class.name].methods[#methods].endline,
		false,
		cpp_lines
	)
end

return M
