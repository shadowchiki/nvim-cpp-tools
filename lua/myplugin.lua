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

M.FileStructure = {
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
			local capture_text = vim.treesitter.get_node_text(node, bufnr)
			table.insert(namespaces, capture_text)
		end
	end

	return namespaces
end

function M.get_class_info()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local class_name = nil
	local methods = {}
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local ts_utils = require("nvim-treesitter.ts_utils")

	-- Navegar por los nodos del árbol para encontrar namespaces
	local root = tree:root()

	local class_number = 1
	local file_structure = M.FileStructure

	file_structure.namespaces = M.get_namespaces()

	local inside_class = false

	for _, line in ipairs(lines) do
		-- Detectar clase
		local class_match = line:match("^%s*class%s+(%w+)")
		if class_match then
			class_name = class_match
			file_structure.classes[class_number].name = class_name
			inside_class = true
		end

		-- Salir de la clase
		if inside_class and line:match("^%s*};") then
			inside_class = false
			class_number = class_number + 1
		end

		-- Detectar constructores, destructores y funciones
		if inside_class then
			local method_match = line:match("^%s*[%w%s%*&]+(%w+)%s*%b()%s*[constvirtualstatic]*%s*;") -- Mejor regex
			if line:match("^%s*[%w%s%*&]+(%w+)%s*%b()%s*[constvirtualstatic]*%s*;") then
				local params = line:match("%((.-)%)") or ""
				table.insert(methods, { name = method_match, params = params })
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

	-- Agregar implementación de métodos
	for _, method in ipairs(file_structure.classes[1].methods) do
		local method_def = file_structure.classes[1].name .. "::" .. method.name .. "(" .. method.params .. ")"
		table.insert(cpp_lines, method_def .. " {")
		table.insert(cpp_lines, "    // TODO: Implementar " .. method.name)
		table.insert(cpp_lines, "}")
		table.insert(cpp_lines, "")
	end

	-- Cerrar namespaces
	for _ = 1, #file_structure.namespaces do
		table.insert(cpp_lines, "}")
	end

	-- Escribir el archivo .cpp
	local file = io.open(cpp_filename, "w")
	if file then
		file:write(table.concat(cpp_lines, "\n"))
		file:close()
		-- print("Archivo generado: " .. cpp_filename)
		vim.cmd("edit " .. cpp_filename)
	else
		print("Error al crear el archivo " .. cpp_filename)
	end
end

vim.keymap.set(
	"n",
	"<leader>co",
	M.remove_unused_includes,
	{ desc = "Remove unused includes", noremap = true, silent = true }
)
vim.keymap.set("n", "gh", "<cmd>ClangdSwitchSourceHeader<CR>", { desc = "Swap .hpp/.cpp files" })
vim.keymap.set(
	"n",
	"<Leader>ci",
	M.generate_cpp_file,
	{ desc = "Generate Implementation", noremap = true, silent = true }
)
return M
