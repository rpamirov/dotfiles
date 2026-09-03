return {
  "lmilojevicc/herdr-splits.nvim",
  cond = vim.env.HERDR_ENV == "1",
  event = "VeryLazy",
  opts = {
    default_amount = 0.03,
    neovim_amount = 3,
    at_edge = "wrap",
    nav_at_edge = "wrap",
    unzoom_on_nav = true,
  },
  config = function(_, opts)
    require("herdr-splits").setup(opts)
  end,
  keys = {
    { "<C-h>", function() require("herdr-splits").move_cursor_left() end, mode = { "n", "x" } },
    { "<C-j>", function() require("herdr-splits").move_cursor_down() end, mode = { "n", "x" } },
    { "<C-k>", function() require("herdr-splits").move_cursor_up() end, mode = { "n", "x" } },
    { "<C-l>", function() require("herdr-splits").move_cursor_right() end, mode = { "n", "x" } },
    { "<A-h>", function() require("herdr-splits").resize_left() end, mode = { "n", "x" } },
    { "<A-j>", function() require("herdr-splits").resize_down() end, mode = { "n", "x" } },
    { "<A-k>", function() require("herdr-splits").resize_up() end, mode = { "n", "x" } },
    { "<A-l>", function() require("herdr-splits").resize_right() end, mode = { "n", "x" } },
  },
}
