local base = require('neotest-haskell.base')
local hspec = require('neotest-haskell.hspec')
local cabal = require("neotest-haskell.cabal")
local stack = require("neotest-haskell.stack")
local lib = require('neotest.lib')
local logger = require("neotest.logging")


local HaskellNeotestAdapter = { name = 'neotest-haskell' }


HaskellNeotestAdapter.root = base.match_project_root_pattern

local is_test_file = base.is_test_file
local filter_dir = base.filter_dir

function HaskellNeotestAdapter.is_test_file(file_path)
  return is_test_file(file_path)
end

function HaskellNeotestAdapter.filter_dir(...)
  return filter_dir(...)
end

---@async
function HaskellNeotestAdapter.discover_positions(path)
  local pos = hspec.parse_positions(path)
  logger.debug("Found positions: " .. vim.inspect(pos))
  return pos
end


---@async
function HaskellNeotestAdapter.build_spec(args)
  local tree = args and args.tree
  if not tree then
    return nil
  end
  local pos = args.tree:data()
  if pos.type ~= "test" then
    return nil
  end

  local mkCommand = function(command)
    return {
      command = command,
      context = {
        file = pos.path,
        pos_id = pos.id,
        pos_path = pos.path,
      },
    }
  end

  local package_root = base.match_package_root_pattern(pos.path)
  local project_root = base.match_project_root_pattern(pos.path)

  if lib.files.exists(project_root .. '/cabal.project') then
    return mkCommand(cabal.build_command(package_root, pos))
  elseif lib.files.exists(project_root .. '/stack.yaml') then
    return mkCommand(stack.build_command(project_root, package_root, pos))
  end

  logger.error('Project is neither a Cabal nor a Stack project.')
end


---@async
function HaskellNeotestAdapter.results(spec, result)
  local pos_id = spec.context.pos_id
  if result.code == 0 then
    return { [pos_id] = {
      status = 'passed'
    } }
  end
  if vim.tbl_contains(spec.command, 'cabal') then
    return cabal.parse_results(spec.context, result.output)
  end
  return stack.parse_results(spec.context, result.output)
end

setmetatable(HaskellNeotestAdapter, {
  __call = function(_, opts)
    is_test_file = opts.is_test_file or is_test_file
    filter_dir = opts.filter_dir or filter_dir
    return HaskellNeotestAdapter
  end,
})

return HaskellNeotestAdapter
