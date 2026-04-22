local M = {}
local notify = require("curl.notifications")

local exists = function(file)
  if vim.uv.fs_stat(file) then
    return true
  end
  return false
end

---comment
---@param global boolean
---@return string
local function get_custom_dir(global)
  if global then
    return "custom"
  else
    local workspace_path = vim.fn.getcwd()
    local unique = vim.fn.fnamemodify(workspace_path, ":t") .. "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
    return "scopedcustom/" .. unique
  end
end

local curl_cache_dir = function(custom_dir)
  local cache_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "curl_cache")

  if custom_dir then
    cache_dir = vim.fs.joinpath(cache_dir, custom_dir)
  end

  local abs_cache_dir = vim.fs.abspath(cache_dir)
  if vim.fn.mkdir(abs_cache_dir, "p") ~= 1 then
    notify.error("Error creating collection: could not create directory : " .. abs_cache_dir)
  end

  return cache_dir
end

---@param filename string
---@return string
M.load_custom_command_file = function(filename, global)
  local custom_dir = get_custom_dir(global)
  local cache_dir = curl_cache_dir(custom_dir)

  local curl_filename = filename .. ".curl"
  local custom_cache_dir = vim.fs.joinpath(cache_dir, curl_filename)
  return vim.fs.abspath(custom_cache_dir)
end

---@return string
M.load_global_command_file = function()
  local cache_dir = curl_cache_dir()

  local global_cache_file = vim.fs.joinpath(cache_dir, "global.curl")
  return vim.fs.abspath(global_cache_file)
end

---@return string
M.load_command_file = function()
  local workspace_path = vim.fn.getcwd()
  local cache_dir = curl_cache_dir()

  local unique_id = vim.fn.fnamemodify(workspace_path, ":t") .. "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
  local new_file_name = unique_id .. ".curl"

  local old_cache_file = vim.fs.joinpath(cache_dir, vim.fn.sha256(workspace_path))
  local new_cache_file = vim.fs.joinpath(cache_dir, new_file_name)

  if exists(old_cache_file) then
    if not exists(new_cache_file) then
      old_cache_file:rename({ new_name = vim.fs.abspath(new_cache_file) })
    else
      local archive_file = vim.fs.joinpath(cache_dir, vim.fn.sha256(workspace_path), ".archive")
      old_cache_file:rename({ new_name = vim.fs.abspath(archive_file) })
    end
  end

  return vim.fs.abspath(new_cache_file)
end

---@param global boolean set to true to search global scorep
---@return table Table of collection in the given scope
M.get_collections = function(global)
  local collection_dir = curl_cache_dir(get_custom_dir(global))
  collection_dir = vim.fs.abspath(collection_dir)

  local scan = require("curl.scandir")

  local filepaths = scan.scan_dir(collection_dir, { depth = 1 }) ---@type string[]

  local files = {}
  for _, filepath in ipairs(filepaths) do
    table.insert(files, vim.fn.fnamemodify(filepath, ":t:r"))
  end

  return files
end

return M
