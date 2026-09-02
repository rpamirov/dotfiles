return {
  "mrjones2014/smart-splits.nvim",
  build = "./kitty/install-kittens.bash",
  extensions = {},
  lazy = false,
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "x" } },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "x" } },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "x" } },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "x" } },
    { "<A-h>", function() require("smart-splits").resize_left() end, mode = { "n", "x" } },
    { "<A-j>", function() require("smart-splits").resize_down() end, mode = { "n", "x" } },
    { "<A-k>", function() require("smart-splits").resize_up() end, mode = { "n", "x" } },
    { "<A-l>", function() require("smart-splits").resize_right() end, mode = { "n", "x" } },
    { "<leader>wh", function() require("smart-splits").swap_buf_left() end, mode = { "n", "x" }, desc='Swap buffer left' },
    { "<leader>wj", function() require("smart-splits").swap_buf_down() end, mode = { "n", "x" }, desc='Swap buffer down' },
    { "<leader>wk", function() require("smart-splits").swap_buf_up() end, mode = { "n", "x" }, desc='Swap buffer right' },
    { "<leader>wl", function() require("smart-splits").swap_buf_right() end, mode = { "n", "x" }, desc='Swap buffer right' },
  },
  cmd = {
    "SmartCursorMoveDown",
    "SmartCursorMoveLeft",
    "SmartCursorMoveRight",
    "SmartCursorMoveUp",
    "SmartResizeDown",
    "SmartResizeLeft",
    "SmartResizeMode",
    "SmartResizeRight",
    "SmartResizeUp",
    "SmartSplitsLog",
    "SmartSplitsLogLevel",
  },
  init = function()
    vim.api.nvim_create_autocmd("UIEnter", {
      callback = function()
        vim.api.nvim_set_keymap("n", "<C-w><C-l>", "", { callback = function() vim.api.nvim_command("nohlsearch") end })
        vim.api.nvim_set_keymap("x", "<C-w><C-l>", "", { callback = function() vim.api.nvim_command("nohlsearch") end })
      end,
      once = true,
    })
  end,
  opts = function(_, opts)
    opts.ignored_buftypes = { "prompt" }

    opts.ignored_filetypes = vim.list_extend(opts.ignored_filetypes or {}, { "lazy" })

    -- Use the same resize step as the Herdr/tmux bindings.
    opts.default_amount = 3

    opts.cursor_follows_swapped_bufs = true

    -- Auto-detect Herdr, tmux, Kitty, or another supported multiplexer.
    -- Herdr takes precedence when HERDR_ENV is present.
    opts.multiplexer_integration = nil
  end,
  config = function(_, opts) require("smart-splits").setup(opts) end,
}
