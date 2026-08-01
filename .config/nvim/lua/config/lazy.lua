local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"
local lazy_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--no-checkout", lazyrepo, lazypath })
  if vim.v.shell_error == 0 then
    out = out .. vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", lazy_commit })
  end
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to install pinned lazy.nvim revision:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
local installed_commit = vim.trim(vim.fn.system({ "git", "-C", lazypath, "rev-parse", "HEAD" }))
local commit_status = vim.v.shell_error
local tracked_changes = vim.trim(vim.fn.system({ "git", "-C", lazypath, "status", "--porcelain", "--untracked-files=no" }))
if commit_status ~= 0 or vim.v.shell_error ~= 0 or installed_commit ~= lazy_commit or tracked_changes ~= "" then
  error("lazy.nvim is not clean at the pinned revision; remove " .. lazypath .. " and restart Neovim")
end
local verifier = vim.fn.expand("~/bin/nvim-plugins")
local verification = vim.fn.system({ verifier, "verify", "--allow-missing" })
if vim.v.shell_error ~= 0 then
  error("Neovim plugin integrity check failed:\n" .. verification)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
