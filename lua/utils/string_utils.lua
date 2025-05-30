local M = {}

function M.trim(string)
	return string:match("^%s*(.-)%s*$")
end

return M
