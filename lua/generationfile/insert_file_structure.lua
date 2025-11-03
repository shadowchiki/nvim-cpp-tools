local M = {}

-- local ts_query = require("nvim-treesitter.query")
local ts_query = require("vim.treesitter.query")
local string_utils = require("utils.string_utils")

function M.is_already_implemented(file_structure, class)
	local is_already_implemented = false
	for _, method in ipairs(file_structure.classes[class.name].methods) do
		if method.name == class.methods[#class.methods].name and method.type == class.methods[#class.methods].type then
			is_already_implemented = true
			break
		end
	end
	return is_already_implemented
end

local function is_empty_constructor(paramsSplit)
	return paramsSplit[1] ~= ""
end

local function split_params(params)
	local params_with_out_parentesis = string.sub(params, 2, -2)
	local params_removed_blanck = params_with_out_parentesis:gsub(", ", ",")
	local params_split = vim.split(params_removed_blanck, ",")
	return params_split
end

local function dispatch_constructor_params(params)
	local param_splited_structure = { params = {} }
	local params_split = split_params(params)
	if is_empty_constructor(params_split) then
		for _, param in ipairs(params_split) do
			local param_splited = vim.split(param, " ")
			if #param_splited == 3 then
				table.insert(
					param_splited_structure.params,
					{ type = param_splited[1] .. " " .. param_splited[2], name = param_splited[3], used = false }
				)
			else
				table.insert(
					param_splited_structure.params,
					{ type = param_splited[1], name = param_splited[2], used = false }
				)
			end
		end
	end
	return param_splited_structure
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

local function check_if_method_return_reference_type(capture_value)
	return string.sub(capture_value, 1, 1) == "&"
end

local function insert_method(actual_class, capture_name, capture_value, start_row, end_row)
	if capture_name == "methodType" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].type = capture_value
		end
	end

	if capture_name == "methodName" and actual_class ~= nil then
		if actual_class then
			capture_value = string.gsub(capture_value, "override", "")
			if check_if_method_return_reference_type(capture_value) then
				capture_value = string.gsub(capture_value, "&", "", 1)
				actual_class.methods[#actual_class.methods].type = actual_class.methods[#actual_class.methods].type
					.. "&"
				capture_value = string_utils.trim(capture_value)
			end
			if actual_class.methods[#actual_class.methods] == nil then
				table.insert(
					actual_class.methods,
					{ type = "", name = capture_value, startline = start_row + 1, endline = end_row + 2 }
				)
			else
				actual_class.methods[#actual_class.methods].name = capture_value
			end
		end
	end

	if capture_name == "methodLine" and actual_class ~= nil then
		if actual_class then
			table.insert(
				actual_class.methods,
				{ type = "", name = "", startline = start_row + 1, endline = end_row + 2 }
			)
		end
	end

	if capture_name == "methodParameters" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].name = actual_class.methods[#actual_class.methods].name
				.. capture_value
		end
	end

	if capture_name == "reference" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].type = actual_class.methods[#actual_class.methods].type .. "&"
		end
	end

	if capture_name == "methodNameRemove" then
		if actual_class then
			table.remove(actual_class.methods, #actual_class.methods)
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

function M.get_class_name_from_method(hpp_classes, method_selected)
	local className = ""
	for _, class in pairs(hpp_classes) do
		for _, method in ipairs(class.methods) do
			if
				method.type == method_selected.type
				and method.name == method_selected.name
				and method.startline == method_selected.startline
			then
				className = class.name
				break
			end
		end
	end
	return className
end

function M.get_class_structure(query)
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser()
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

	local result = ts_query.get("cpp", query)
	local actual_class = ""

	for id, node in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local capture_value = vim.treesitter.get_node_text(node, bufnr)
		local start_row, _, end_row, _ = node:range()

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
		insert_method(file_structure.classes[actual_class], capture_name, capture_value, start_row, end_row)
		insert_attribute(file_structure.classes[actual_class], capture_name, capture_value)
	end

	return file_structure
end

return M
