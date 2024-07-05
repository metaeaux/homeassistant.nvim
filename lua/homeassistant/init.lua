local M = {}
local curl = require("plenary.curl")
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
  vim.lsp.util.open_floating_preview(
    vim.split(lines, "\n"),
    "markdown",
    {
      max_height = 60,
      max_width = 60,
    }
  )
end

local function on_setup()
  vim.api.nvim_create_user_command("HARender", function(args)
    local b = vim.api.nvim_get_current_buf()
    if args.range == 0 then
      return M.display_result(M.template_from_buffer { buf = b, line1 = 0, line2 = -1 })
    else
      return M.display_result(M.template_from_buffer { buf = b, line1 = args.line1, line2 = args.line2 })
    end
  end, {
    range = 2,
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
