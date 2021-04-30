local Keys = require("which-key.keys")
local Util = require("which-key.util")

---@class WhichKey
local M = {}

function M.setup(options) require("which-key.config").setup(options) end

function M.execute(id) Keys.functions(id)() end

function M.show(keys, opts)
  opts = opts or {}
  if type(opts) == "string" then opts = { mode = opts } end

  keys = keys or ""

  -- mappings will pass <lt> as <, so change it back
  keys = keys:gsub("[<]", "<lt>")

  opts.mode = opts.mode or Util.get_mode()
  local buf = vim.api.nvim_get_current_buf()
  -- make sure the trees exist for update
  Keys.get_tree(opts.mode)
  Keys.get_tree(opts.mode, buf)
  -- update only trees related to buf
  Keys.update(buf)
  -- trigger which key
  require("which-key.view").open(keys, opts)
end

function M.show_command(keys, mode)
  keys = (keys == "\"\"" or keys == "''") and "" or keys
  mode = (mode == "\"\"" or mode == "''") and "" or mode
  mode = mode or "n"
  keys = Util.t(keys)
  if not Util.check_mode(mode) then
    Util.error(
      "Invalid mode passed to :WhichKey (Dont create any keymappings to trigger WhichKey. WhichKey does this automaytically)")
  else
    M.show(keys, { mode = mode })
  end
end

local queue = {}
local loaded = false -- once we loaded everything

-- Defer registering keymaps until VimEnter
function M.register(mappings, opts)
  if loaded then
    Keys.register(mappings, opts)
    Keys.update()
  else
    table.insert(queue, { mappings, opts })
  end
end

-- Load mappings and update only once
function M.load()
  require("which-key.plugins").setup()
  require("which-key.colors").setup()
  Keys.register({}, { prefix = "<leader>", mode = "n" })
  Keys.register({}, { prefix = "<leader>", mode = "v" })
  Keys.setup()

  for _, reg in pairs(queue) do
    local opts = reg[2] or {}
    opts.update = false
    Keys.register(reg[1], opts)
  end
  Keys.update()
  queue = {}
  loaded = true
end

function M.reset()
  -- local mappings = Keys.mappings
  require("plenary.reload").reload_module("which-key")
  -- require("which-key.Keys").mappings = mappings
  require("which-key").setup()
end

return M
