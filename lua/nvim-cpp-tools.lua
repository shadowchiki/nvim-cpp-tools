local M = {}

function M.setup(user_config)
	require("config.keymap").setup()
	require("config.config").setup(user_config)
end

return M
