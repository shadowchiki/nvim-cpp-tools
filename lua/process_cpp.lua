local M = {}

function M.process_namespaces(cpp_lines, namespaces)
	for _, ns in ipairs(namespaces) do
		table.insert(cpp_lines, "namespace " .. ns .. " {")
	end
end

function M.contains(attribute, param)
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

function M.find_attribute_by_type_and_name(attribute, params)
	local inicialize_value = ""
	local iterator = 1
	local finded = false
	while iterator <= #params and finded == false do
		local param = params[iterator]
		if
			M.contains(attribute.type, param.type)
			and M.contains(attribute.name, param.name)
			and param.used == false
		then
			inicialize_value = param.name
			param.used = true
			finded = true
		end
		iterator = iterator + 1
	end
	return inicialize_value
end

function M.find_attribute_by_type(attribute, params)
	local inicialize_value = ""
	local iterator = 1
	local finded = false
	while iterator <= #params and finded == false do
		local param = params[iterator]
		if M.contains(attribute.type, param.type) and param.used == false then
			inicialize_value = param.name
			param.used = true
			finded = true
		end
		iterator = iterator + 1
	end
	return inicialize_value
end

function M.inicialize_attribute_with_constructor_param(attribute, params)
	if #params == 0 then
		return ""
	end
	local inicialize_value = M.find_attribute_by_type_and_name(attribute, params)
	if inicialize_value == "" then
		inicialize_value = M.find_attribute_by_type(attribute, params)
	end
	return inicialize_value
end

function M.process_constructor(class, cpp_lines)
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
				local param_to_attribute = M.inicialize_attribute_with_constructor_param(attribute, constructor.params)
					.. ")"
				table.insert(result, param_to_attribute)
				table.insert(cpp_lines, param_to_attribute)
				if key ~= #class.attributes then
					table.insert(cpp_lines, ", ")
				end
			end
		end

		table.insert(cpp_lines, "{}")
		table.insert(cpp_lines, "")
	end
end

function M.process_destructor(class, cpp_lines)
	if class.needDestructor then
		table.insert(cpp_lines, class.name .. "::" .. "~" .. class.name .. "()" .. "{")
		table.insert(cpp_lines, "}\n")
		table.insert(cpp_lines, "")
	end
end

function M.process_methods(class, cpp_lines)
	for _, method in ipairs(class.methods) do
		table.insert(cpp_lines, method.type .. " " .. class.name .. "::" .. method.name .. "{")
		table.insert(cpp_lines, "}")
		table.insert(cpp_lines, "")
	end
end

function M.close_namespaces(cpp_lines, file_structure)
	for _ = 1, #file_structure.namespaces do
		table.insert(cpp_lines, "}")
	end
end

function M.process_file_structure(file_structure)
	local h_filename = vim.api.nvim_buf_get_name(0)
	local cpp_lines = {
		'#include "' .. h_filename:match("([^/]+)$") .. '"',
		"",
	}

	M.process_namespaces(cpp_lines, file_structure.namespaces)
	table.insert(cpp_lines, "\n")
	for _, class in pairs(file_structure.classes) do
		M.process_constructor(class, cpp_lines)
		M.process_destructor(class, cpp_lines)
		M.process_methods(class, cpp_lines)
	end
	M.close_namespaces(cpp_lines, file_structure)
	return cpp_lines
end

return M
