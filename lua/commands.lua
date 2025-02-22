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
			table.insert(paramSplitedStructure.params, { type = paramSplited[1], name = paramSplited[2], used = false })
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

local function create_test_file(file_name, results)
	local file = io.open(vim.fn.expand(file_name), "w") -- Guardar en home
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

	local result = ts_query.get_query("cpp", "class")
	local actual_class = ""

	for id, node in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)

		if capture_name == "namespace" then
			table.insert(file_structure.namespaces, capture_value)
		end

		if capture_name == "className" then
			if not file_structure.classes[capture_value] then
				file_structure.classes[capture_value] = {
					name = capture_value,
					inheritances = {},
					constructors = {},
					attributes = {},
					methods = {},
					needDestructor = false,
				}
			end
			actual_class = capture_value
		end
		insert_inheritance(file_structure.classes[actual_class], capture_name, capture_value)
		insert_constructor(file_structure.classes[actual_class], capture_name, capture_value)
		insert_destructor(file_structure.classes[actual_class], capture_name)
		insert_method(file_structure.classes[actual_class], capture_name, capture_value)
		insert_attribute(file_structure.classes[actual_class], capture_name, capture_value)
	end

	local results = {}
	for id, node, _ in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local text = vim.treesitter.get_node_text(node, bufnr)
		table.insert(results, capture_name .. ": " .. text)
	end
	create_test_file("query_result.txt", results)

	return file_structure
end

local function process_namespaces(cpp_lines, namespaces)
	for _, ns in ipairs(namespaces) do
		table.insert(cpp_lines, "namespace " .. ns .. " {")
	end
end

local function contains(attribute, param)
	local big_string = ""
	local small_string = ""
	if #attribute >= #param then
		big_string = attribute
		small_string = param
	else
		big_string = param
		small_string = attribute
	end
	return string.find(string.lower(big_string), string.lower(small_string))
end

local function find_attribute_by_type_and_name(attribute, params)
	local inicialize_value = ""
	local iterator = 1
	local finded = false
	while iterator <= #params and finded == false do
		local param = params[iterator]
		if contains(attribute.type, param.type) and contains(attribute.name, param.name) and param.used == false then
			inicialize_value = param.name
			param.used = true
			finded = true
		end
		iterator = iterator + 1
	end
	return inicialize_value
end

local function find_attribute_by_type(attribute, params)
	local inicialize_value = ""
	local iterator = 1
	local finded = false
	while iterator <= #params and finded == false do
		local param = params[iterator]
		if contains(attribute.type, param.type) and param.used == false then
			inicialize_value = param.name
			param.used = true
			finded = true
		end
		iterator = iterator + 1
	end
	return inicialize_value
end

local function inicialize_attribute_with_constructor_param(attribute, params)
	if #params == 0 then
		return ""
	end
	local inicialize_value = find_attribute_by_type_and_name(attribute, params)
	if inicialize_value == "" then
		inicialize_value = find_attribute_by_type(attribute, params)
	end
	return inicialize_value
end

local function process_constructor(class, cpp_lines)
	local result = {}
	table.insert(result, class.name)
	for _, constructor in ipairs(class.constructors) do
		table.insert(cpp_lines, class.name .. "::" .. class.name .. "(")
		if #constructor.params ~= 0 then
			for key, param in ipairs(constructor.params) do
				table.insert(cpp_lines, param.type .. " " .. param.name)
				if key ~= #constructor.params then
					table.insert(cpp_lines, ", ")
				else
				end
			end
		end
		table.insert(cpp_lines, ")")

		if #class.inheritances ~= 0 or #class.attributes ~= 0 then
			table.insert(cpp_lines, ":")
		end

		if #class.inheritances ~= 0 then
			for key, inherance in ipairs(class.inheritances) do
				table.insert(cpp_lines, " " .. inherance .. "()")
				if key ~= #class.inheritances then
					table.insert(cpp_lines, ", ")
				else
					if #class.attributes ~= 0 then
						table.insert(cpp_lines, ",")
					end
				end
			end
		end

		if #class.attributes ~= 0 then
			for key, attribute in ipairs(class.attributes) do
				table.insert(cpp_lines, " " .. attribute.name .. "(")
				local param_to_attribute = inicialize_attribute_with_constructor_param(attribute, constructor.params)
					.. ")"
				table.insert(result, param_to_attribute)
				table.insert(cpp_lines, param_to_attribute)
				if key ~= #class.attributes then
					table.insert(cpp_lines, ", ")
				end
			end
		end

		table.insert(cpp_lines, "{}\n")
	end
	local file = io.open("constructor_process.txt", "w")
	if file then
		file:write(table.concat(result, "\n"))
		file:close()
	end
end

local function process_destructor(class, cpp_lines)
	if class.needDestructor then
		table.insert(cpp_lines, class.name .. "::" .. "~" .. class.name .. "()" .. "{")
		table.insert(cpp_lines, "}\n")
	end
end

local function process_methods(class, cpp_lines)
	for _, method in ipairs(class.methods) do
		table.insert(cpp_lines, method.type .. " " .. class.name .. "::" .. method.name .. "{")
		table.insert(cpp_lines, "}\n")
	end
end

local function close_namespaces(cpp_lines, file_structure)
	for _ = 1, #file_structure.namespaces do
		table.insert(cpp_lines, "}")
	end
end

local function create_cpp_file(cpp_lines, h_filename)
	local cpp_filename = h_filename:gsub("%.h$", ".cpp"):gsub("%.hpp$", ".cpp")
	local file = io.open(cpp_filename, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		vim.cmd("edit " .. cpp_filename)
		vim.lsp.buf.format()
	else
		print("Cant create file: " .. cpp_filename)
	end
end

function M.generate_cpp_file()
	local file_structure = M.get_class_structure()
	if #file_structure.classes <= 0 then
		print("No classes in the file")
		return
	end
	local h_filename = vim.api.nvim_buf_get_name(0)
	local cpp_lines = {
		'#include "' .. h_filename:match("([^/]+)$") .. '"',
		"",
	}

	process_namespaces(cpp_lines, file_structure.namespaces)
	table.insert(cpp_lines, "\n")
	for _, class in pairs(file_structure.classes) do
		process_constructor(class, cpp_lines)
		process_destructor(class, cpp_lines)
		process_methods(class, cpp_lines)
	end
	close_namespaces(cpp_lines, file_structure)
	create_cpp_file(cpp_lines, h_filename)
end
return M
