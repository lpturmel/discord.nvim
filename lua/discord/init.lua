local vim = vim
local fn = vim.fn
local api = vim.api
local loop = vim.loop

local M = {}

local binary_name = "nvim-discord"
local os_name = loop.os_uname().sysname
local binary_path = (os_name == "Windows_NT") and (binary_name .. ".exe") or binary_name

local job_id ---@type integer|nil
local warned_missing = false

local function have_binary()
	return fn.executable(binary_path) == 1
end

local function start_binary()
	if job_id and job_id > 0 then
		return true
	end
	if not have_binary() then
		if not warned_missing then
			warned_missing = true
			vim.notify(
				("'%s' not found in PATH. Discord RPC is disabled."):format(binary_path),
				vim.log.levels.WARN,
				{ title = "nvim-discord" }
			)
		end
		return false
	end

	local id = fn.jobstart(binary_path, {
		on_stdout = function(_, _, _) end,
		on_stderr = function(_, data, _)
			if data and #data > 0 and (data[1] or "") ~= "" then
				vim.schedule(function()
					vim.notify(table.concat(data, "\n"), vim.log.levels.WARN, { title = "nvim-discord (stderr)" })
				end)
			end
		end,
		on_exit = function()
			job_id = nil
		end,
	})

	if type(id) ~= "number" or id <= 0 then
		if not warned_missing then
			warned_missing = true
			vim.notify(
				("Failed to start '%s' (not in PATH or could not exec). Discord RPC disabled."):format(binary_path),
				vim.log.levels.WARN,
				{ title = "nvim-discord" }
			)
		end
		return false
	end

	job_id = id
	return true
end

local function send_current_file_name()
	if not start_binary() then
		return
	end

	local current_file = api.nvim_buf_get_name(0)
	local message = { type = "file_change", file_name = fn.fnamemodify(current_file, ":t") }
	local json = fn.json_encode(message) .. "\n"

	if not job_id or job_id <= 0 then
		return
	end

	local ok = pcall(fn.jobsend, job_id, json)
	if not ok then
		job_id = nil
	end
end

function M.setup()
	local grp = api.nvim_create_augroup("NvimDiscordRPC", { clear = true })
	api.nvim_create_autocmd("BufEnter", {
		group = grp,
		pattern = "*",
		callback = function()
			vim.schedule(send_current_file_name)
		end,
	})
end

return M
