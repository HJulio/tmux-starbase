-- treemux's own config, then two local changes: transparent background, and files open in a
-- simple editor instead of Neovim.
dofile(vim.fn.expand("~/.tmux-starbase/plugins/treemux/configs/treemux_init.lua"))

-- Editor for files picked in the tree; its pane closes when the editor quits.
-- $STARBASE_EDITOR wins; otherwise Fresh if installed, then $EDITOR, then nano.
local EDITOR = vim.env.STARBASE_EDITOR
  or (vim.fn.executable("fresh") == 1 and "fresh")
  or vim.env.EDITOR
  or "nano"

local function clear_bg()
  for _, group in ipairs({
    "Normal", "NormalNC", "EndOfBuffer", "SignColumn", "WinSeparator",
    "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer", "NvimTreeWinSeparator",
  }) do
    vim.cmd("highlight " .. group .. " guibg=NONE ctermbg=NONE")
  end
  -- bold names read better at the terminal font size (the tree cannot have a font size of its own)
  for _, group in ipairs({
    "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeFolderName", "NvimTreeOpenedFolderName",
    "NvimTreeEmptyFolderName", "NvimTreeRootFolder", "NvimTreeExecFile", "NvimTreeSpecialFile",
  }) do
    vim.cmd("highlight " .. group .. " gui=bold cterm=bold")
  end
end
clear_bg()
vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_bg })

local function open_in_editor()
  local api = require("nvim-tree.api")
  local node = api.tree.get_node_under_cursor()
  if not node or node.type ~= "file" then
    return api.node.open.edit() -- folders expand/collapse as usual
  end
  -- split above the pane the tree belongs to, same place treemux used for its Neovim editor
  vim.fn.system({
    "tmux", "split-window", "-v", "-b", "-l", "70%",
    "-t", vim.g.nvim_tree_remote_tmux_pane,
    "-c", vim.fn.fnamemodify(node.absolute_path, ":h"),
    EDITOR, node.absolute_path,
  })
end

-- scheduled so these win over the mappings treemux sets in its own on_attach
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function(ev)
    vim.schedule(function()
      for _, key in ipairs({ "<CR>", "l", "o", "<C-t>", "<2-LeftMouse>" }) do
        vim.keymap.set("n", key, open_in_editor, { buffer = ev.buf, nowait = true, silent = true, desc = "Open in " .. EDITOR })
      end
    end)
  end,
})
