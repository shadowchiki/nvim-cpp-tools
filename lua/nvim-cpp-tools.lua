local M = {}

function M.setup(user_config)
	require("keymap").setup()
	require("config").setup(user_config)
end

return M
