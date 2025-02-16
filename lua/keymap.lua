local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "cpp", "c", "cc", "h", "hpp" },
		callback = function()
			local commands = require("commands")
			vim.keymap.set(
				"n",
				"<leader>co",
				commands.remove_unused_includes,
				{ desc = "Remove unused includes", noremap = true, silent = true }
			)
			vim.keymap.set("n", "gh", "<cmd>ClangdSwitchSourceHeader<CR>", { desc = "Swap .hpp/.cpp files" })
			vim.keymap.set(
				"n",
				"<Leader>ci",
				commands.generate_cpp_file,
				{ desc = "Generate Implementation", noremap = true, silent = true }
			)
			vim.api.nvim_buf_create_user_command(
				0,
				"RemoveUnusedIncludes",
				commands.remove_unused_includes,
				{ desc = "Remove unused includes" }
			)
			vim.api.nvim_buf_create_user_command(
				0,
				"GenerateCppImplementation",
				commands.generate_cpp_file,
				{ desc = "Generate Implementation" }
			)
		end,
	})
end

return M
