local M = {}

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
