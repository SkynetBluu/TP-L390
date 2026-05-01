# modules/home/neovim.nix
# Neovim — full IDE setup with LSP, completion, treesitter, AI

{ pkgs, config, theme, ... }:

{
  programs.neovim = {
    enable         = true;
    package        = pkgs.neovim-unwrapped;
    defaultEditor  = true;
    viAlias        = true;
    vimAlias       = true;
    vimdiffAlias   = true;
    withPython3    = true;
    withRuby       = false;

    plugins = with pkgs.vimPlugins; [
      # Core
      plenary-nvim lualine-nvim
      # Colorschemes
      catppuccin-nvim tokyonight-nvim nord-nvim monokai-pro-nvim
      # UI
      alpha-nvim noice-nvim nui-nvim nvim-notify dressing-nvim
      nvim-web-devicons bufferline-nvim indent-blankline-nvim which-key-nvim
      # File navigation
      neo-tree-nvim telescope-nvim telescope-fzf-native-nvim
      oil-nvim flash-nvim harpoon2 aerial-nvim
      # Git
      gitsigns-nvim lazygit-nvim vim-fugitive diffview-nvim neogit
      # LSP & completion
      nvim-lspconfig lsp_signature-nvim trouble-nvim
      nvim-cmp cmp-nvim-lsp cmp-nvim-lsp-signature-help
      cmp-buffer cmp-path cmp-cmdline cmp_luasnip lspkind-nvim
      luasnip friendly-snippets
      # Formatting & linting
      conform-nvim nvim-lint
      # Treesitter
      nvim-treesitter.withAllGrammars nvim-treesitter-context
      # Code intelligence
      nvim-autopairs comment-nvim nvim-surround todo-comments-nvim
      vim-repeat vim-illuminate nvim-hlslens nvim-ufo promise-async
      # AI
      copilot-lua copilot-cmp codecompanion-nvim
      # GitHub
      octo-nvim
      # Debugging
      nvim-dap nvim-dap-ui nvim-dap-virtual-text
      # Utilities
      toggleterm-nvim persistence-nvim nvim-spectre nvim-colorizer-lua
      nvim-bqf nvim-scrollbar markdown-preview-nvim
      mini-nvim
    ];

    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server nil ruff rust-analyzer
      vscode-langservers-extracted bash-language-server
      gopls yaml-language-server marksman
      # Formatters
      nixpkgs-fmt alejandra stylua black isort prettierd shfmt rustfmt
      # Linters
      statix deadnix shellcheck eslint_d
      # Tools
      nodejs tree-sitter curl gh
    ];

    initLua = ''
      vim.g.mapleader      = " "
      vim.g.maplocalleader = "\\"
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1
      if vim.loader then vim.loader.enable() end

      local opt = vim.opt
      opt.number         = true
      opt.relativenumber = true
      opt.tabstop        = 2
      opt.shiftwidth     = 2
      opt.expandtab      = true
      opt.smartindent    = true
      opt.breakindent    = true
      opt.ignorecase     = true
      opt.smartcase      = true
      opt.hlsearch       = true
      opt.inccommand     = "split"
      opt.termguicolors  = true
      opt.cursorline     = true
      opt.signcolumn     = "yes"
      opt.colorcolumn    = "100"
      opt.pumheight      = 12
      opt.mouse          = "a"
      opt.clipboard      = "unnamedplus"
      opt.wrap           = false
      opt.confirm        = true
      opt.completeopt    = { "menu", "menuone", "noselect" }
      opt.scrolloff      = 8
      opt.sidescrolloff  = 8
      opt.splitright     = true
      opt.splitbelow     = true
      opt.updatetime     = 150
      opt.timeoutlen     = 350
      opt.undofile       = true
      opt.swapfile       = false
      opt.backup         = false
      opt.undolevels     = 10000
      opt.foldcolumn     = "1"
      opt.foldlevel      = 99
      opt.foldlevelstart = 99
      opt.foldenable     = true

      -- Colorscheme
      require("catppuccin").setup({
        flavour = "${theme.appearance.nvimFlavor}",
        transparent_background = false,
        integrations = {
          gitsigns = true, neotree = true, notify = true,
          telescope = true, treesitter = true, which_key = true,
        },
      })
      vim.cmd([[colorscheme catppuccin]])

      -- Lualine
      require("lualine").setup({
        options = {
          theme = "auto",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators   = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })

      -- Bufferline
      require("bufferline").setup({
        options = {
          numbers      = "ordinal",
          diagnostics  = "nvim_lsp",
          separator_style = "thin",
        },
      })

      -- Which-key
      local wk = require("which-key")
      wk.setup({ preset = "modern", delay = 300 })

      -- Neo-tree
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
        },
        window = { width = 35 },
      })

      -- Telescope
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          file_ignore_patterns = { "node_modules", ".git/", "dist/", "__pycache__" },
        },
      })
      telescope.load_extension("fzf")

      -- LSP
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = { text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN]  = " ",
          [vim.diagnostic.severity.HINT]  = "󰌵 ",
          [vim.diagnostic.severity.INFO]  = " ",
        }},
        float = { border = "rounded", source = "always" },
      })

      local servers = {
        nil_ls = {}, lua_ls = {}, pyright = {}, rust_analyzer = {},
        ts_ls = {}, gopls = {}, clangd = {}, yamlls = {},
        marksman = {}, html = {}, cssls = {}, jsonls = {}, bashls = {},
      }
      for server, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        vim.lsp.config[server] = cfg
      end
      vim.lsp.enable(vim.tbl_keys(servers))

      -- nvim-cmp
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        window  = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
        mapping = cmp.mapping.preset.insert({
          ["<C-j>"]     = cmp.mapping.select_next_item(),
          ["<C-k>"]     = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "copilot",  priority = 900 },
          { name = "luasnip",  priority = 750 },
          { name = "buffer",   priority = 500, keyword_length = 3 },
          { name = "path",     priority = 250 },
        }),
      })

      -- Conform (format on save)
      require("conform").setup({
        formatters_by_ft = {
          nix        = { "nixpkgs_fmt" },
          lua        = { "stylua" },
          python     = { "isort", "black" },
          javascript = { "prettierd" }, typescript = { "prettierd" },
          json       = { "prettierd" }, html = { "prettierd" },
          css        = { "prettierd" }, markdown = { "prettierd" },
          sh         = { "shfmt" },    rust = { "rustfmt" },
        },
        format_on_save = { timeout_ms = 800, lsp_format = "fallback" },
      })

      -- Treesitter — on NixOS withAllGrammars handles parser setup
      -- We just enable highlight/indent via the configs module if available
      local ts_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if ts_ok then
        ts_configs.setup({
          highlight = { enable = true },
          indent    = { enable = true },
        })
      else
        -- Fallback: enable treesitter highlight natively (nvim 0.9+)
        vim.api.nvim_create_autocmd("FileType", {
          callback = function()
            pcall(vim.treesitter.start)
          end,
        })
      end
      local ctx_ok, ts_context = pcall(require, "treesitter-context")
      if ctx_ok then
        ts_context.setup({ enable = true, max_lines = 3 })
      end

      -- Git
      require("gitsigns").setup({
        signs = { add = { text = "│" }, change = { text = "│" }, delete = { text = "_" } },
      })
      require("neogit").setup({})
      require("diffview").setup({})

      -- Other plugins
      require("nvim-autopairs").setup({})
      require("Comment").setup({})
      require("todo-comments").setup({})
      require("nvim-surround").setup({})
      require("flash").setup({})
      require("harpoon"):setup({})
      require("oil").setup({ columns = { "icon" }, view_options = { show_hidden = true } })
      require("persistence").setup({})
      require("trouble").setup({})
      require("toggleterm").setup({ open_mapping = [[<C-\>]], direction = "horizontal", size = 15 })
      require("aerial").setup({ layout = { default_direction = "right", placement = "edge" } })
      require("copilot").setup({ suggestion = { enabled = true, auto_trigger = true } })
      require("ibl").setup({ indent = { char = "│" } })
      require("colorizer").setup({})
      require("ufo").setup({ provider_selector = function() return { "treesitter", "indent" } end })
      require("noice").setup({
        lsp = { override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        }},
        presets = { bottom_search = true, command_palette = true, lsp_doc_border = true },
      })

      -- Keymaps
      local map = vim.keymap.set
      map("n", "<Esc>",   "<cmd>noh<CR><Esc>",  { desc = "Clear search" })
      map("i", "jk",      "<Esc>",               { desc = "Exit insert" })
      map("n", "<C-s>",   "<cmd>w<CR>",          { desc = "Save" })
      map("i", "<C-s>",   "<Esc><cmd>w<CR>a",    { desc = "Save" })
      map("n", "<C-b>",   "<cmd>Neotree toggle<CR>", { desc = "Explorer" })
      map("n", "<C-p>",   "<cmd>Telescope find_files<CR>", { desc = "Find file" })
      map("n", "<C-h>",   "<C-w>h", { desc = "Window left" })
      map("n", "<C-j>",   "<C-w>j", { desc = "Window down" })
      map("n", "<C-k>",   "<C-w>k", { desc = "Window up" })
      map("n", "<C-l>",   "<C-w>l", { desc = "Window right" })
      map("v", "<",       "<gv",    { desc = "Indent left" })
      map("v", ">",       ">gv",    { desc = "Indent right" })
      map("v", "p",       '"_dP',   { desc = "Paste without yank" })
      map("n", "<A-j>",   "<cmd>m .+1<CR>==",    { desc = "Move line down" })
      map("n", "<A-k>",   "<cmd>m .-2<CR>==",    { desc = "Move line up" })
      map("n", "zR",      function() require("ufo").openAllFolds() end,  { desc = "Open all folds" })
      map("n", "zM",      function() require("ufo").closeAllFolds() end, { desc = "Close all folds" })
      map("n", "s", function() require("flash").jump() end,        { desc = "Flash jump" })
      map("n", "S", function() require("flash").treesitter() end,  { desc = "Flash treesitter" })
      map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent dir (Oil)" })

      wk.add({
        { "<leader>w",  "<cmd>w<CR>",                desc = "Save" },
        { "<leader>q",  "<cmd>q<CR>",                desc = "Quit" },
        { "<leader>e",  "<cmd>Neotree toggle<CR>",   desc = "Explorer" },
        { "<leader>?",  "<cmd>WhichKey<CR>",         desc = "All keybinds" },
        { "<leader>f",  group = "Find" },
        { "<leader>ff", "<cmd>Telescope find_files<CR>",  desc = "Find file" },
        { "<leader>fg", "<cmd>Telescope live_grep<CR>",   desc = "Grep" },
        { "<leader>fb", "<cmd>Telescope buffers<CR>",     desc = "Buffers" },
        { "<leader>fr", "<cmd>Telescope oldfiles<CR>",    desc = "Recent" },
        { "<leader>g",  group = "Git" },
        { "<leader>gg", "<cmd>LazyGit<CR>",               desc = "LazyGit" },
        { "<leader>gd", "<cmd>DiffviewOpen<CR>",          desc = "Diff view" },
        { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "Line blame" },
        { "<leader>c",  group = "Code" },
        { "<leader>ca", vim.lsp.buf.code_action,          desc = "Code action" },
        { "<leader>cr", vim.lsp.buf.rename,               desc = "Rename" },
        { "<leader>cf", function() require("conform").format() end, desc = "Format" },
        { "<leader>x",  group = "Diagnostics" },
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics" },
        { "<leader>t",  group = "Terminal" },
        { "<leader>tt", "<cmd>ToggleTerm<CR>",            desc = "Toggle terminal" },
        { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Float terminal" },
        { "<leader>a",  group = "AI" },
        { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", desc = "AI chat" },
        { "<leader>aa", "<cmd>CodeCompanionActions<CR>",     desc = "AI actions" },
      })

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          map("n", "gd", vim.lsp.buf.definition,    vim.tbl_extend("force", opts, { desc = "Definition" }))
          map("n", "gr", "<cmd>Telescope lsp_references<CR>", vim.tbl_extend("force", opts, { desc = "References" }))
          map("n", "K",  vim.lsp.buf.hover,          vim.tbl_extend("force", opts, { desc = "Hover docs" }))
        end,
      })

      -- Highlight on yank
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function() vim.highlight.on_yank({ higroup = "Visual", timeout = 120 }) end,
      })
    '';
  };
}
