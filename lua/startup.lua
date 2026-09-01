-- Better startup screen when no files are opened (extracted from init.lua).
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 then
      local oldfiles = vim.v.oldfiles
      local lines = { "  Recent files:", "" }
      local count = 0
      for i = 1, #oldfiles do
        local file = oldfiles[i]
        if vim.fn.filereadable(file) == 1 then
          count = count + 1
          lines[#lines + 1] = "  " .. count .. ". " .. vim.fn.fnamemodify(file, ":~:.")
          if count >= 10 then break end
        end
      end
      if count == 0 then
        lines[#lines + 1] = "  (no recent files)"
      end
      lines[#lines + 1] = ""
      lines[#lines + 1] = "  Commands:"
      lines[#lines + 1] = "  <leader><space>  Find files"
      lines[#lines + 1] = "  <leader>?        Live grep"
      lines[#lines + 1] = "  <leader>e        File explorer"
      lines[#lines + 1] = "  <leader>gg       Lazygit"
      lines[#lines + 1] = "  <leader>lq       LeetCode (DSA)"
      lines[#lines + 1] = "  <leader>ac       AI chat"
      lines[#lines + 1] = "  <leader>aa       AI actions"
      lines[#lines + 1] = "  <leader>dd       Debug start"
      lines[#lines + 1] = "  <leader>db       Debug breakpoint"
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.bo.modifiable = false
      vim.bo.bufhidden = "wipe"
      vim.bo.swapfile = false
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"
    end
  end,
})
