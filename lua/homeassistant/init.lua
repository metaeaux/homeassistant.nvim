local M = {}
local curl = require("plenary.curl")
local notify = require("notify")
_G._homeassistant = M

M.template = function(lines)
  local res = curl.post(M.url .. "/api/template", {
    headers = M.headers(),
    body = vim.json.encode({ template = table.concat(lines, "\n") }),
  })
  if res.status ~= 200 then
    error(res.body)
  end
  return res.body
end

M.template_from_buffer = function(opts)
  local lines = vim.api.nvim_buf_get_lines(opts.buf, opts.line1, opts.line2, false)
  return M.template(lines)
end

M.display_result = function(lines)
  notify(lines, "info", { title = 'Home Assistant' })
end

local function on_setup()
  vim.api.nvim_create_user_command("HARender", function(args)
    local m = vim.fn.mode()                      -- detect current mode
    local l1 = 0
    local l2 = -1
    if m == 'v' or m == 'V' or m == '\22' then   -- <C-V>
      vim.cmd([[execute "normal! \<ESC>"]])
      l1 = vim.fn.getpos("'<")[2]
      l2 = vim.fn.getpos("'>")[2]
    end
    local b = vim.api.nvim_get_current_buf()
    return M.display_result(M.template_from_buffer { buf = b, line1 = l1, line2 = l2 })
  end, {
    range = true,
    bang = true,
  })
end

M.setup = function(opts)
  vim.validate {
    url = { opts.url, 's' },
    token = { opts.token, 's' },
  }
  M.url = opts.url
  -- Wrap the headers in a function to not expose the token so easily
  M.headers = function()
    return {
      ["Authorization"] = "Bearer " .. opts.token,
      ["Content-Type"] = "application/json",
    }
  end
  on_setup()
end


return M
