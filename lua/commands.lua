local ts_query = require("nvim-treesitter.query")

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

local function isEmptyConstructor(paramsSplit)
	return paramsSplit[1] ~= ""
end

local function splitParams(params)
	local paramsWithOutParentesis = params:gsub("[()]", "")
	local paramsRemovedBlanck = paramsWithOutParentesis:gsub(", ", ",")
	local paramsSplit = vim.split(paramsRemovedBlanck, ",")
	return paramsSplit
end

local function dispatch_constructor_params(params)
	local paramSplitedStructure = { params = {} }
	local paramsSplit = splitParams(params)
	if isEmptyConstructor(paramsSplit) then
		for _, param in ipairs(paramsSplit) do
			local paramSplited = vim.split(param, " ")
			table.insert(paramSplitedStructure.params, { type = paramSplited[1], name = paramSplited[2] })
		end
	end
	return paramSplitedStructure
end

local function insert_inheritance(actual_class, capture_name, capture_value)
	if capture_name == "inheritance" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.inheritances, capture_value)
		end
	end
end

local function insert_constructor(actual_class, capture_name, capture_value)
	if capture_name == "constructorParamList" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.constructors, dispatch_constructor_params(capture_value))
		end
	end
end

local function insert_destructor(actual_class, capture_name)
	if capture_name == "destructor" and actual_class ~= nil then
		if actual_class then
			actual_class.needDestructor = true
		end
	end
end

local function insert_method(actual_class, capture_name, capture_value)
	if capture_name == "methodType" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.methods, { type = capture_value, name = "" })
		end
	end

	if capture_name == "methodName" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].name = capture_value
		end
	end
end

local function insert_attribute(actual_class, capture_name, capture_value)
	if capture_name == "attributeType" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.attributes, { type = capture_value, name = "" })
		end
	end

	if capture_name == "attributeName" and actual_class ~= nil then
		if actual_class then
			actual_class.attributes[#actual_class.attributes].name = capture_value
		end
	end
end

local function test_query_result(bufnr, result, root)
	local results = {}
	for id, node, _ in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local text = vim.treesitter.get_node_text(node, bufnr)
		table.insert(results, capture_name .. ": " .. text)
	end
	local file = io.open(vim.fn.expand("query_result.txt"), "w") -- Guardar en home
	if file then
		file:write(table.concat(results, "\n"))
		file:close()
	end
end

function M.get_class_structure()
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

	local result = ts_query.get_query("cpp", "class")
	local actual_class = ""
	local class_count = 1

	for id, node in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)
		if capture_name == "className" then
			if not file_structure.classes[capture_value] then
				file_structure.classes[capture_value] = {
					name = capture_value,
					inheritances = {},
					order = class_count,
					constructors = {},
					attributes = {},
					methods = {},
					needDestructor = false,
				}
				class_count = class_count + 1
			end
			actual_class = capture_value
		end
		insert_inheritance(file_structure.classes[actual_class], capture_name, capture_value)
		insert_constructor(file_structure.classes[actual_class], capture_name, capture_value)
		insert_destructor(file_structure.classes[actual_class], capture_name)
		insert_method(file_structure.classes[actual_class], capture_name, capture_value)
		insert_attribute(file_structure.classes[actual_class], capture_name, capture_value)
	end

	test_query_result(bufnr, result, root)

	table.sort(file_structure.classes, function(a, b)
		return a.order < b.order
	end)
	return file_structure
end

function M.generate_cpp_file()
	local file_structure = M.get_class_structure()
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

	for _, ns in ipairs(file_structure.namespaces) do
		table.insert(cpp_lines, "namespace " .. ns .. " {")
	end

	table.insert(cpp_lines, "\n")

	for _, class in pairs(file_structure.classes) do
		for _, constructor in ipairs(class.constructors) do
			table.insert(cpp_lines, class.name .. "::" .. class.name .. "(")
			if #constructor.params ~= 0 then
				for key, param in ipairs(constructor.params) do
					if key ~= #constructor.params then
						table.insert(cpp_lines, param.type .. " " .. param.name .. ", ")
					else
						table.insert(cpp_lines, param.type .. " " .. param.name)
					end
				end
			end
			table.insert(cpp_lines, ")")

			if #class.inheritances ~= 0 or #class.attributes ~= 0 then
				table.insert(cpp_lines, ":")
			end

			if #class.inheritances ~= 0 then
				for key, inherance in ipairs(class.inheritances) do
					if key ~= #class.inheritances then
						table.insert(cpp_lines, " " .. inherance .. "(), ")
					else
						table.insert(cpp_lines, " " .. inherance .. "()")
						if #class.attributes ~= 0 then
							table.insert(cpp_lines, ",")
						end
					end
				end
			end

			if #class.attributes ~= 0 then
				for key, attribute in ipairs(class.attributes) do
					if key ~= #class.attributes then
						table.insert(cpp_lines, " " .. attribute.name .. "(), ")
					else
						table.insert(cpp_lines, " " .. attribute.name .. "()")
					end
				end
			end

			table.insert(cpp_lines, "{}\n")
		end
		if class.needDestructor then
			table.insert(cpp_lines, class.name .. "::" .. "~" .. class.name .. "()" .. "{")
			table.insert(cpp_lines, "}\n")
		end
		for _, method in ipairs(class.methods) do
			table.insert(cpp_lines, method.type .. " " .. class.name .. "::" .. method.name .. "{")
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
