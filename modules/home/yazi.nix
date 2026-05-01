# modules/home/yazi.nix
# Yazi — terminal file manager

{ pkgs, theme, ... }:

{
  home.packages = with pkgs; [
    yazi
    unar # archive extraction
    imv # lightweight Wayland image viewer
  ];

  # UEBERZUGPP_BACKEND = wayland still creates overlay windows on Alacritty
  # since Alacritty has no inline graphics protocol support.
  # Previewers are limited to text/code/pdf until terminal is upgraded.

  xdg.configFile."yazi/yazi.toml".text = ''
    [manager]
    ratio          = [1, 3, 4]
    sort_by        = "natural"
    sort_sensitive = false
    sort_reverse   = false
    show_hidden    = false
    show_symlink   = true

    [preview]
    tab_size   = 2
    max_width  = 900
    max_height = 900

    [plugin]
    previewers = [
      { name = "*/",              run = "folder", sync = true },
      { mime = "text/*",          run = "code" },
      { mime = "application/pdf", run = "pdf" },
      { mime = "*",               run = "file" },
    ]

    [opener]
    play = [
      { run = "mpv %s", desc = "Play in mpv", for = "unix" }
    ]
    edit = [
      { run = "nvim %s", desc = "Edit in Neovim", block = true, for = "unix" }
    ]
    view = [
      { run = "imv %s", desc = "Open in imv", for = "unix" }
    ]
    pdf = [
      { run = "brave %s", desc = "Open in Brave", for = "unix" }
    ]
    extract = [
      { run = "unar %s", desc = "Extract here", for = "unix" }
    ]

    [open]
    rules = [
      { mime = "video/*",             use = "play" },
      { mime = "audio/*",             use = "play" },
      { mime = "image/*",             use = "view" },
      { mime = "application/pdf",     use = "pdf" },
      { mime = "text/*",              use = "edit" },
      { mime = "application/json",    use = "edit" },
      { mime = "application/toml",    use = "edit" },
      { mime = "application/yaml",    use = "edit" },
      { mime = "application/zip",     use = "extract" },
      { mime = "application/gzip",    use = "extract" },
      { mime = "application/x-tar",   use = "extract" },
      { mime = "application/x-bzip2", use = "extract" },
      { mime = "application/x-xz",    use = "extract" },
      { mime = "application/x-zstd",  use = "extract" },
    ]
  '';

  xdg.configFile."yazi/keymap.toml".text = ''
    [manager]
    keymap = [
      # Navigation
      { on = "k",       run = "arrow -1",              desc = "Up" },
      { on = "j",       run = "arrow 1",               desc = "Down" },
      { on = "h",       run = "leave",                 desc = "Go to parent" },
      { on = "l",       run = "enter",                 desc = "Enter directory / open file" },
      { on = "g g",     run = "arrow -99999999",       desc = "Go to top" },
      { on = "G",       run = "arrow 99999999",        desc = "Go to bottom" },
      { on = "<Left>",  run = "leave",                 desc = "Go to parent" },
      { on = "<Right>", run = "enter",                 desc = "Enter / open" },
      { on = "<Up>",    run = "arrow -1",              desc = "Up" },
      { on = "<Down>",  run = "arrow 1",               desc = "Down" },

      # Selection
      { on = "<Space>", run = "select --state=none",   desc = "Toggle selection" },
      { on = "v",       run = "visual_mode",           desc = "Visual mode" },
      { on = "V",       run = "select_all --state=none", desc = "Select all" },

      # File operations
      { on = "y",       run = "yank",                  desc = "Copy" },
      { on = "x",       run = "yank --cut",            desc = "Cut" },
      { on = "p",       run = "paste",                 desc = "Paste" },
      { on = "P",       run = "paste --force",         desc = "Paste (overwrite)" },
      { on = "d",       run = "remove",                desc = "Move to trash" },
      { on = "D",       run = "remove --permanently",  desc = "Delete permanently" },
      { on = "a",       run = "create",                desc = "Create file/directory" },
      { on = "r",       run = "rename",                desc = "Rename" },

      # View
      { on = ".",       run = "hidden toggle",         desc = "Toggle hidden files" },
      { on = "z",       run = "cd --interactive",      desc = "Jump with fzf" },
      { on = "/",       run = "find",                  desc = "Find" },
      { on = "n",       run = "find_arrow",            desc = "Next match" },
      { on = "N",       run = "find_arrow --previous", desc = "Prev match" },

      # Tabs
      { on = "t",       run = "tab_create --current",     desc = "New tab" },
      { on = "[",       run = "tab_switch -1 --relative", desc = "Prev tab" },
      { on = "]",       run = "tab_switch 1 --relative",  desc = "Next tab" },
      { on = "<Tab>",   run = "tab_switch 1 --relative",  desc = "Next tab" },

      # Shell
      { on = "!",       run = "shell --interactive",   desc = "Shell" },
      { on = "q",       run = "quit",                  desc = "Quit" },
      { on = "<Esc>",   run = "escape",                desc = "Escape" },
    ]
  '';

  xdg.configFile."yazi/theme.toml".text = ''
    # Catppuccin Mocha — matches system theme

    [manager]
    cwd = { fg = "${theme.colors.blue}" }

    hovered         = { fg = "${theme.colors.background}", bg = "${theme.colors.blue}" }
    preview_hovered = { underline = true }

    find_keyword  = { fg = "${theme.colors.yellow}", bold = true, italic = true, underline = true }
    find_position = { fg = "${theme.colors.magenta}", bold = true, italic = true }

    marker_copied   = { fg = "${theme.colors.green}",  bg = "${theme.colors.green}" }
    marker_cut      = { fg = "${theme.colors.red}",    bg = "${theme.colors.red}" }
    marker_selected = { fg = "${theme.colors.blue}",   bg = "${theme.colors.blue}" }

    tab_active   = { fg = "${theme.colors.background}", bg = "${theme.colors.blue}" }
    tab_inactive = { fg = "${theme.colors.foreground}", bg = "${theme.colors.surface}" }

    border_symbol = "│"
    border_style  = { fg = "${theme.colors.border}" }

    [status]
    separator_open  = ""
    separator_close = ""
    separator_style = { fg = "${theme.colors.surface}", bg = "${theme.colors.surface}" }

    mode_normal = { fg = "${theme.colors.background}", bg = "${theme.colors.blue}",    bold = true }
    mode_select = { fg = "${theme.colors.background}", bg = "${theme.colors.green}",   bold = true }
    mode_unset  = { fg = "${theme.colors.background}", bg = "${theme.colors.magenta}", bold = true }

    progress_label  = { bold = true }
    progress_normal = { fg = "${theme.colors.blue}",  bg = "${theme.colors.surface}" }
    progress_error  = { fg = "${theme.colors.red}",   bg = "${theme.colors.surface}" }

    permissions_t = { fg = "${theme.colors.blue}" }
    permissions_r = { fg = "${theme.colors.yellow}" }
    permissions_w = { fg = "${theme.colors.red}" }
    permissions_x = { fg = "${theme.colors.green}" }
    permissions_s = { fg = "${theme.colors.foregroundDim}" }

    [input]
    border   = { fg = "${theme.colors.blue}" }
    title    = {}
    value    = {}
    selected = { reversed = true }

    [completion]
    border   = { fg = "${theme.colors.blue}" }
    active   = { bg = "${theme.colors.surface}" }
    inactive = {}

    [tasks]
    border  = { fg = "${theme.colors.blue}" }
    title   = {}
    hovered = { underline = true }

    [which]
    mask            = { bg = "${theme.colors.surface}" }
    cand            = { fg = "${theme.colors.blue}" }
    rest            = { fg = "${theme.colors.foregroundDim}" }
    desc            = { fg = "${theme.colors.magenta}" }
    separator       = "  "
    separator_style = { fg = "${theme.colors.border}" }

    [help]
    on      = { fg = "${theme.colors.blue}" }
    exec    = { fg = "${theme.colors.magenta}" }
    desc    = { fg = "${theme.colors.foregroundDim}" }
    hovered = { bg = "${theme.colors.surface}", bold = true }
    footer  = { fg = "${theme.colors.background}", bg = "${theme.colors.blue}" }

    [filetype]
    rules = [
      { mime = "image/*",             fg = "${theme.colors.yellow}" },
      { mime = "video/*",             fg = "${theme.colors.magenta}" },
      { mime = "audio/*",             fg = "${theme.colors.cyan}" },
      { mime = "application/zip",     fg = "${theme.colors.red}" },
      { mime = "application/gzip",    fg = "${theme.colors.red}" },
      { mime = "application/x-tar",   fg = "${theme.colors.red}" },
      { mime = "application/x-xz",    fg = "${theme.colors.red}" },
      { mime = "application/pdf",     fg = "${theme.colors.orange}" },
      { name = "*.sh",                fg = "${theme.colors.green}" },
      { name = "*.nix",               fg = "${theme.colors.blue}" },
      { name = "*/",                  fg = "${theme.colors.blue}", bold = true },
    ]
  '';
}
