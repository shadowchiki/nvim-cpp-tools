local process_cpp = require("generationfile.process_cpp")
local insert_file_structure = require("generationfile.insert_file_structure")
local M = {}

local attributes = {
	{ name = "Generate", type = "std::shared_ptr<Excursion>" },
	{ name = "All", type = "std::shared_ptr<Excursion>", marked = false },
	-- { name = "mAttribute1", type = "std::shared_ptr<Excursion>", marked = false },
	-- { name = "mAttribute2", type = "std::string", marked = false },
}

function M.calculate_marker(prev_selected_name)
	-- Para pintar los nombres, hay que comprobar si el listado de clases es > 1, en caso de que sea true hay que poner el nombre de la clase delante de cada atributo
	for i, attr in ipairs(attributes) do
		local marker = ""
		if attr.marked ~= nil and attr.marked == false and attr.name == prev_selected_name then
			marker = "✓ "
			attr.marked = true
		elseif attr.marked ~= nil and attr.marked == true and attr.name == prev_selected_name then
			marker = ""
			attr.marked = false
		elseif attr.marked ~= nil and attr.marked == true then
			marker = "✓ "
		end
		attr.display = string.format("%s%d: %s", marker, i, attr.name)
	end
end

function M.attribute_menu(prev_selected_name)
	M.calculate_marker(prev_selected_name)
	vim.ui.select(attributes, {
		prompt = "Choose an attribute",
		format_item = function(item)
			return item.display
		end,
	}, function(choice)
		if choice ~= nil and choice.name ~= "Generate" and choice.name ~= "All" then
			M.attribute_menu(choice.name)
		end
	end)
end

function M.prepare_options()
	local options = {
		{
			name = "Getters and Setters",
			type = "gas",
			execution = function(attribute, cpp_lines)
				process_cpp.process_getter(attribute, cpp_lines)
				process_cpp.process_setter(attribute, cpp_lines)
			end,
		},
		{
			name = "Getters",
			type = "g",
			execution = function(attribute, cpp_lines)
				process_cpp.process_getter(attribute, cpp_lines)
			end,
		},
		{
			name = "Setters",
			type = "s",
			execution = function(attribute, cpp_lines)
				process_cpp.process_setter(attribute, cpp_lines)
			end,
		},
	}
	for i, item in ipairs(options) do
		item.display = string.format("%d: %s", i, item.name)
	end
	return options
end

function M.generate_getters_and_setters()
	local entries = M.prepare_options()
	local selection = {}
	vim.ui.select(entries, {
		prompt = "Choose an option",
		format_item = function(item)
			return item.display
		end,
	}, function(choice)
		if choice then
			selection = choice
			local file_structure = insert_file_structure.get_class_structure("class")

			for _, class in pairs(file_structure.classes) do
				print("Attribute " .. class.name .. " key " .. _)
				for _, attribute in pairs(class.attributes) do
					attribute.marked = false
					table.insert(attributes, class)
				end
			end
			M.attribute_menu("")
		end
	end)

	local process_all = false
	local cpp_lines = {}
	for _, value in pairs(attributes) do
		if process_all == true then
			selection:execution(value, cpp_lines)
		elseif value.name == "All" and value.marked == true then
			process_all = true
			selection:execution(value, cpp_lines)
		elseif value.marked ~= nil and value.marked == true and process_all == false then
			selection:execution(value, cpp_lines)
		end
	end
end

return M
