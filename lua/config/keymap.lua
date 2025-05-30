local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "cpp", "c", "cc", "h", "hpp" },
		callback = function()
			local generate_method_implementation = require("generate_method_implementation")
			local unused_includes = require("remove_unused_includes")
			local generate_cpp_file = require("generate_cpp_file")
			vim.keymap.set(
				"n",
				"<leader>co",
				unused_includes.remove_unused_includes,
				{ desc = "Remove unused includes", noremap = true, silent = true }
			)
			vim.keymap.set("n", "gh", "<cmd>ClangdSwitchSourceHeader<CR>", { desc = "Swap .hpp/.cpp files" })
			vim.keymap.set(
				"n",
				"<leader>cI",
				generate_method_implementation.generate_method_implementation,
				{ desc = "Generate Method Implementation", noremap = false }
			)
			vim.keymap.set(
				"n",
				"<Leader>ci",
				generate_cpp_file.generate_cpp_file,
				{ desc = "Generate Implementation", noremap = true, silent = true }
			)
			vim.api.nvim_buf_create_user_command(
				0,
				"RemoveUnusedIncludes",
				unused_includes.remove_unused_includes,
				{ desc = "Remove unused includes" }
			)
			vim.api.nvim_buf_create_user_command(
				0,
				"GenerateMethodImplementation",
				generate_method_implementation.generate_method_implementation,
				{ desc = "Gnerate Method Implementation" }
			)
			vim.api.nvim_buf_create_user_command(
				0,
				"GenerateCppImplementation",
				generate_cpp_file.generate_cpp_file,
				{ desc = "Generate Implementation" }
			)
		end,
	})
end

return M
