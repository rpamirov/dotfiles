return {
  "LazyVim/LazyVim",
  opts = {
    extras = {
      { "lang/python", lazyvim_python_lsp = "ruff_lsp" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff_lsp = {
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
              callback = function()
                vim.lsp.buf.code_action({
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {}, -- optional
                  },
                  apply = true,
                })
              end,
              buffer = bufnr,
            })
          end,
        },
      },
    },
  },
}
