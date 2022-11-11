local hspec = require('neotest-haskell.hspec')
local logger = require("neotest.logging")

local M = {}

---@async
M.build_command = function(package_root, pos)
  logger.debug('Building spec for Cabal project...')
  local command = {
    'cabal',
    'test',
  }
  local test_opts = hspec.get_cabal_test_opts(pos)
  return test_opts
      and vim.list_extend(command, test_opts)
      or command
end

---@async
M.parse_results = function(context, out_path)
  return hspec.parse_results(context, out_path)
end

return M
