local M = {}

function M.remove_unused_includes()
	local bufnr = vim.api.nvim_get_current_buf()
	local diagnostics = vim.diagnostic.get(bufnr)
	local lines_to_remove = {}
	for _, diag in ipairs(diagnostics) do
		if diag.code == "unused-includes" then
			table.insert(lines_to_remove, diag.lnum)
		end
	end
	table.sort(lines_to_remove, function(a, b)
		return a > b
	end)
	for _, line in ipairs(lines_to_remove) do
		vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, {})
	end
end

function M.get_namespaces()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()
	local namespaces = {}

	local queryNested = "(nested_namespace_specifier) @namespace"
	local query = "(namespace_definition name: (namespace_identifier) @namespace)"
	local result = vim.treesitter.query.parse("cpp", queryNested)
	for _, node in result:iter_captures(root, bufnr) do
		local capture_text = vim.treesitter.get_node_text(node, bufnr)
		table.insert(namespaces, capture_text)
	end

	if #namespaces == 0 then
		result = vim.treesitter.query.parse("cpp", query)
		for _, node in result:iter_captures(root, bufnr) do
			table.insert(namespaces, vim.treesitter.get_node_text(node, bufnr))
		end
	end

	return namespaces
end

function M.get_class_info()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]

	local root = tree:root()

	local file_structure = {
		namespaces = {},
		classes = {
			{
				name = "",
				constructors = {},
				methods = {},
				needDestructor = false,
			},
		},
	}

	file_structure.namespaces = M.get_namespaces()

	local queryString =
		"(class_specifier name: (type_identifier) @className) (class_specifier body: (field_declaration_list (declaration declarator: (function_declarator declarator: (destructor_name) @destructor)))) (class_specifier body: (field_declaration_list (declaration declarator: (function_declarator declarator: (identifier) parameters: (parameter_list)) @parameterList))) (class_specifier name: (type_identifier) body: (field_declaration_list (field_declaration type: [(qualified_identifier) (primitive_type)] @type declarator: (function_declarator) @methodName)))"

	local result = vim.treesitter.query.parse("cpp", queryString)
	local actual_class = ""
	local method_combination_counter = 0
	for id, node in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local text_name = vim.treesitter.get_node_text(node, bufnr)
		if capture_name == "className" then
			if not file_structure.classes[text_name] then
				file_structure.classes[text_name] = {
					name = text_name,
					constructors = {},
					methods = {},
					needDestructor = false,
				}
			end
			actual_class = text_name
		end
		if capture_name == "parameterList" and actual_class ~= nil then
			if file_structure.classes[actual_class] then
				table.insert(file_structure.classes[actual_class].constructors, text_name)
			end
		end
		if capture_name == "destructor" and actual_class ~= nil then
			if file_structure.classes[actual_class] then
				file_structure.classes[actual_class].needDestructor = true
			end
		end

		if capture_name == "type" and actual_class ~= nil then
			if file_structure.classes[actual_class] and method_combination_counter == 0 then
				table.insert(file_structure.classes[actual_class].methods, { type = text_name, name = "" })
				method_combination_counter = method_combination_counter + 1
			end
		end

		if capture_name == "methodName" and actual_class ~= nil then
			if file_structure.classes[actual_class] and method_combination_counter == 1 then
				file_structure.classes[actual_class].methods[#file_structure.classes[actual_class].methods].name =
					text_name
				method_combination_counter = 0
			end
		end
	end
	return file_structure
end

function M.generate_cpp_file()
	local file_structure = M.get_class_info()
	if #file_structure.classes <= 0 then
		print("No se encontró ninguna clase en el archivo actual.")
		return
	end

	local h_filename = vim.api.nvim_buf_get_name(0)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")

	local cpp_lines = {
		'#include "' .. h_filename:match("([^/]+)$") .. '"',
		"",
	}

	-- Abrir namespaces
	for _, ns in ipairs(file_structure.namespaces) do
		table.insert(cpp_lines, "namespace " .. ns .. " {")
	end

	table.insert(cpp_lines, "\n")

	for _, value in pairs(file_structure.classes) do
		for _, each in ipairs(value.constructors) do
			table.insert(cpp_lines, value.name .. "::" .. each .. "{")
			table.insert(cpp_lines, "}\n")
		end
		if value.needDestructor then
			table.insert(cpp_lines, value.name .. "::" .. "~" .. value.name .. "()" .. "{")
			table.insert(cpp_lines, "}\n")
		end
		for _, method in ipairs(value.methods) do
			table.insert(cpp_lines, method.type .. " " .. value.name .. "::" .. method.name .. "{")
			table.insert(cpp_lines, "}\n")
		end
	end

	for _ = 1, #file_structure.namespaces do
		table.insert(cpp_lines, "}")
	end

	local file = io.open(cpp_filename, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		vim.cmd("edit " .. cpp_filename)
	else
		print("Error al crear el archivo " .. cpp_filename)
	end
end
return M
