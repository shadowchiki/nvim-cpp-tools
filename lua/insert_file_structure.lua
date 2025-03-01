local M = {}

local ts_query = require("nvim-treesitter.query")

function M.isEmptyConstructor(paramsSplit)
	return paramsSplit[1] ~= ""
end

function M.splitParams(params)
	local paramsWithOutParentesis = params:gsub("[()]", "")
	local paramsRemovedBlanck = paramsWithOutParentesis:gsub(", ", ",")
	local paramsSplit = vim.split(paramsRemovedBlanck, ",")
	return paramsSplit
end

function M.dispatch_constructor_params(params)
	local paramSplitedStructure = { params = {} }
	local paramsSplit = M.splitParams(params)
	if M.isEmptyConstructor(paramsSplit) then
		for _, param in ipairs(paramsSplit) do
			local paramSplited = vim.split(param, " ")
			table.insert(paramSplitedStructure.params, { type = paramSplited[1], name = paramSplited[2], used = false })
		end
	end
	return paramSplitedStructure
end

function M.insert_inheritance(actual_class, capture_name, capture_value)
	if capture_name == "inheritance" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.inheritances, capture_value)
		end
	end
end

function M.insert_constructor(actual_class, capture_name, capture_value)
	if capture_name == "constructorParamList" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.constructors, M.dispatch_constructor_params(capture_value))
		end
	end
end

function M.insert_destructor(actual_class, capture_name)
	if capture_name == "destructor" and actual_class ~= nil then
		if actual_class then
			actual_class.needDestructor = true
		end
	end
end

function M.insert_method(actual_class, capture_name, capture_value, node_line)
	if capture_name == "methodType" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].type = capture_value
		end
	end

	if capture_name == "methodName" and actual_class ~= nil then
		if actual_class then
			actual_class.methods[#actual_class.methods].name = capture_value
		end
	end

	if capture_name == "methodLine" and actual_class ~= nil then
		if actual_class then
			table.insert(actual_class.methods, { type = "", name = "", line = node_line + 1 })
		end
	end

	if capture_name == "methodNameRemove" then
		if actual_class then
			table.remove(actual_class.methods, #actual_class.methods)
		end
	end
end

function M.insert_attribute(actual_class, capture_name, capture_value)
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

function M.create_test_file(file_name, results)
	local file = io.open(vim.fn.expand(file_name), "w") -- Guardar en home
	if file then
		file:write(table.concat(results, "\n"))
		file:close()
	end
end

M.actual_class = ""

function M.get_class_name_from_method(hpp_classes, method_selected)
	local className = ""
	for _, class in pairs(hpp_classes) do
		for _, method in ipairs(class.methods) do
			if
				method.type == method_selected.type
				and method.name == method_selected.name
				and method.line == method_selected.line
			then
				className = class.name
				break
			end
		end
	end
	return className
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
		M.insert_inheritance(file_structure.classes[actual_class], capture_name, capture_value)
		M.insert_constructor(file_structure.classes[actual_class], capture_name, capture_value)
		M.insert_destructor(file_structure.classes[actual_class], capture_name)
		M.insert_method(file_structure.classes[actual_class], capture_name, capture_value, node:range())
		M.insert_attribute(file_structure.classes[actual_class], capture_name, capture_value)
	end

	local results = {}
	for id, node, _ in result:iter_captures(root, bufnr) do
		local capture_name = result.captures[id]
		local text = vim.treesitter.get_node_text(node, bufnr)
		table.insert(results, capture_name .. ": " .. text)
	end
	M.create_test_file("query_result.txt", results)

	return file_structure
end

return M
