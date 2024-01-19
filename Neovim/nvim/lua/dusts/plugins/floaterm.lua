return {
  {
    "voldikss/vim-floaterm",
    config = function()
      -- Key mapping for normal mode
      vim.api.nvim_set_keymap('n', '<Leader>ft', [[:FloatermToggle<CR>]], { noremap = true, silent = true })

      -- Key mapping for terminal mode
      vim.api.nvim_set_keymap('t', '<Leader>ft', [[<C-\><C-n>:FloatermToggle<CR>]], { noremap = true, silent = true })
    end
  }
}
