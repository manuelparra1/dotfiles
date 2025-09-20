-- lspconfig.lua
return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local on_attach = function(_, bufnr)
			-- Define a helper function for cleaner keymaps
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true, buffer = bufnr })
			end

			-- LSP keybindings
			map("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references")
			map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
			map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Show LSP definitions")
			map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations")
			map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions")
			map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "See available code actions")
			map("n", "<leader>rn", vim.lsp.buf.rename, "Smart rename")
			map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Show buffer diagnostics")
			map("n", "<leader>d", vim.diagnostic.open_float, "Show line diagnostics")
			-- Updated to use the new vim.diagnostic.jump() API:
			map("n", "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, "Go to previous diagnostic")
			map("n", "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, "Go to next diagnostic")
			map("n", "K", vim.lsp.buf.hover, "Show documentation for what is under cursor")
			map("n", "<leader>rs", ":LspRestart<CR>", "Restart LSP")
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- (Updated way) Change the Diagnostic symbols in the sign column (gutter)
		-- ==========================================================================
		-- Define diagnostic symbols using the new API (avoids deprecated sign_define)
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "󰠠",
					[vim.diagnostic.severity.INFO] = "",
				},
			},
		})

		-- configure html server
		lspconfig["html"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure css server
		lspconfig["cssls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure python server
		lspconfig["pyright"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure lua server (with special settings)
		lspconfig["lua_ls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = { -- custom settings for lua
				Lua = {
					-- make the language server recognize "vim" global
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						-- make language server aware of runtime files
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})
	end,
}
