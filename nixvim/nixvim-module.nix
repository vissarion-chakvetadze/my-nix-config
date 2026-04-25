{
  opts = {
    number = true;
    relativenumber = true;
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    autoread = true;
    mousescroll = "ver:1,hor:1";
  };

  colorschemes.catppuccin = {
    enable = true;
    settings.flavour = "mocha";
  };

  plugins = {
    telescope.enable = true;
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        ensure_installed = [ "javascript" "typescript" "tsx" "css" "html" "json" ];
      };
    };
    neo-tree = {
      enable = true;
      settings.filesystem.use_libuv_file_watcher = true;
    };
    web-devicons.enable = true;
    which-key.enable = true;
    lualine.enable = true;
    trouble.enable = true;
    gitsigns.enable = true;
    lsp = {
      enable = true;
      servers = {
        ts_ls.enable = true;
        nixd.enable = true;
        eslint.enable = true;
        biome.enable = true;
      };
    };
  };

  keymaps = [
    { key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; }
    { key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; }
    { key = "<leader>e";  action = "<cmd>Neotree toggle<cr>"; }
    { key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; }
  ];

  extraConfigLua = ''
    vim.fn.timer_start(1000, function()
      vim.cmd("silent! checktime")
    end, { ["repeat"] = -1 })

    vim.diagnostic.config({
      virtual_text = { prefix = "●" },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "✗",
          [vim.diagnostic.severity.WARN]  = "⚠",
          [vim.diagnostic.severity.INFO]  = "ℹ",
          [vim.diagnostic.severity.HINT]  = "○",
        },
      },
      underline = true,
      severity_sort = true,
    })
  '';
}
