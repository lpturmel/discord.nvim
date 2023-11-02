local vim = vim
local fn = vim.fn
local api = vim.api
local jobstart = vim.fn.jobstart
local jobsend = vim.fn.jobsend
local loop = vim.loop

local binary_name = "nvim-discord"

local os_name = loop.os_uname().sysname
local binary_path
if os_name == "Windows_NT" then
  binary_path = binary_name .. ".exe"
else
  binary_path = binary_name
end

local M = {}

-- Function to send the current file name to the binary
local function send_current_file_name()
  local current_file = api.nvim_buf_get_name(0)
  local message = { type = "file_change", file_name = fn.fnamemodify(current_file, ":t") }
  local json_message = vim.fn.json_encode(message)

  -- Start the binary process if it's not already running
  if not _G.binary_job_id then
    _G.binary_job_id = jobstart(binary_path, {
      on_stdout = function(_, data, _)
        if data then
          print("Binary says: " .. table.concat(data, "\n"))
        end
      end,
      on_stderr = function(_, data, _)
        if data then
          print("Binary error: " .. table.concat(data, "\n"))
        end
      end,
      on_exit = function()
        _G.binary_job_id = nil
      end,
    })
  end

  -- Send the JSON message to the binary
  jobsend(_G.binary_job_id, json_message .. "\n")
end


function M.setup()
    -- Autocommand that triggers when the buffer is entered
    api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = send_current_file_name
    })
end

return M
