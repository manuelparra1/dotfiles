return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    lazy = false,
    config = function()
      local mason = require("mason")
      local mason_lspconfig = require("mason-lspconfig")

      mason.setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      mason_lspconfig.setup({
        lazy = false,
        ensure_installed = {
          "tsserver",
          "html",
          "cssls",
          "tailwindcss",
          "svelte",
          "lua_ls",
          "graphql",
          "emmet_ls",
          "prismals",
          "pyright",
        },
        automatic_installation = true,
        auto_install = true,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      local opts = { noremap = true, silent = true }
      local on_attach = function(client, bufnr)
        print("LSP Started")
        opts.buffer = bufnr

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end

      lspconfig.tsserver.setup({
        capabilities = capabilities,
      })
      lspconfig.html.setup({
        capabilities = capabilities,
      })
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
      })

      -- configure python server
      lspconfig["pyright"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      })

      -- Bash Language Server
      lspconfig.bashls.setup({
        cmd = { "bash-language-server", "start" },
        filetypes = { "sh", "bash" },
        capabilities = capabilities,
        on_attach = function(client)
          -- Additional on_attach configurations if needed
          print("Bash Language Server started!")
        end,
      })

      vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {})
      vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", {})
      vim.api.nvim_set_keymap("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", {})
      vim.api.nvim_set_keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", {})
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      local mason_tool_installer = require("mason-tool-installer")

      mason_tool_installer.setup({
        ensure_installed = {
          "prettier",
          "stylua",
          "isort",
          "black",
          "pylint",
          "eslint_d",
        },
      })
    end,
  },
}

