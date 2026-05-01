# modules/home/yazi.nix
# Yazi — terminal file manager
# Sandboxed via firejail in modules/system/security.nix

{ pkgs, theme, ... }:

{
  # Yazi config — openers, previewer, theme
  # The yazi binary itself is firejail-wrapped at system level

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

    [opener]
    # Video and audio → mpv
    play = [
      { run = "mpv '$@'", desc = "Play in mpv", for = "unix" }
    ]
    # Text → nvim in current terminal
    edit = [
      { run = "nvim '$@'", desc = "Edit in Neovim", block = true, for = "unix" }
    ]
    # Images → brave (or swap for an image viewer if you add one)
    view = [
      { run = "brave '$@'", desc = "Open in Brave", for = "unix" }
    ]
    # PDFs → brave
    pdf = [
      { run = "brave '$@'", desc = "Open in Brave", for = "unix" }
    ]
    # Archives → extract in place
    extract = [
      { run = "unar '$@'", desc = "Extract here", for = "unix" }
    ]

    [open]
    rules = [
      # Video
      { mime = "video/*",       use = "play" },
      # Audio
      { mime = "audio/*",       use = "play" },
      # Images
      { mime = "image/*",       use = "view" },
      # PDF
      { mime = "application/pdf", use = "pdf" },
      # Text and code
      { mime = "text/*",        use = "edit" },
      { mime = "application/json", use = "edit" },
      { mime = "application/toml", use = "edit" },
      { mime = "application/yaml", use = "edit" },
      # Archives
      { mime = "application/zip",  use = "extract" },
      { mime = "application/gzip", use = "extract" },
      { mime = "application/x-tar", use = "extract" },
      { mime = "application/x-bzip2", use = "extract" },
      { mime = "application/x-xz",    use = "extract" },
      { mime = "application/x-zstd",  use = "extract" },
    ]
  '';

  xdg.configFile."yazi/keymap.toml".text = ''
    [manager]
    keymap = [
      # Navigation
      { on = "k",        run = "arrow -1",            desc = "Up" },
      { on = "j",        run = "arrow 1",             desc = "Down" },
      { on = "h",        run = "leave",               desc = "Go to parent" },
      { on = "l",        run = "enter",               desc = "Enter directory / open file" },
      { on = "g g",      run = "arrow -99999999",     desc = "Go to top" },
      { on = "G",        run = "arrow 99999999",      desc = "Go to bottom" },
      { on = "<Left>",   run = "leave",               desc = "Go to parent" },
      { on = "<Right>",  run = "enter",               desc = "Enter / open" },
      { on = "<Up>",     run = "arrow -1",            desc = "Up" },
      { on = "<Down>",   run = "arrow 1",             desc = "Down" },

      # Selection
      { on = "<Space>",  run = "select --state=none", desc = "Toggle selection" },
      { on = "v",        run = "visual_mode",         desc = "Visual mode" },
      { on = "V",        run = "select_all --state=none", desc = "Select all" },

      # File operations
      { on = "y",        run = "yank",                desc = "Copy" },
      { on = "x",        run = "yank --cut",          desc = "Cut" },
      { on = "p",        run = "paste",               desc = "Paste" },
      { on = "P",        run = "paste --force",       desc = "Paste (overwrite)" },
      { on = "d",        run = "remove",              desc = "Move to trash" },
      { on = "D",        run = "remove --permanently", desc = "Delete permanently" },
      { on = "a",        run = "create",              desc = "Create file/directory" },
      { on = "r",        run = "rename",              desc = "Rename" },

      # View
      { on = ".",        run = "hidden toggle",       desc = "Toggle hidden files" },
      { on = "z",        run = "cd --interactive",    desc = "Jump with fzf" },
      { on = "/",        run = "find",                desc = "Find" },
      { on = "n",        run = "find_arrow",          desc = "Next match" },
      { on = "N",        run = "find_arrow --previous", desc = "Prev match" },

      # Tabs
      { on = "t",        run = "tab_create --current", desc = "New tab" },
      { on = "[",        run = "tab_switch -1 --relative", desc = "Prev tab" },
      { on = "]",        run = "tab_switch 1 --relative",  desc = "Next tab" },
      { on = "<Tab>",    run = "tab_switch 1 --relative",  desc = "Next tab" },

      # Shell
      { on = "!",        run = "shell --interactive", desc = "Shell" },
      { on = "q",        run = "quit",                desc = "Quit" },
      { on = "<Esc>",    run = "escape",              desc = "Escape" },
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

    marker_copied  = { fg = "${theme.colors.green}",  bg = "${theme.colors.green}" }
    marker_cut     = { fg = "${theme.colors.red}",    bg = "${theme.colors.red}" }
    marker_selected = { fg = "${theme.colors.blue}",  bg = "${theme.colors.blue}" }

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
      # Images
      { mime = "image/*",    fg = "${theme.colors.yellow}" },
      # Video
      { mime = "video/*",    fg = "${theme.colors.magenta}" },
      # Audio
      { mime = "audio/*",    fg = "${theme.colors.cyan}" },
      # Archives
      { mime = "application/zip",   fg = "${theme.colors.red}" },
      { mime = "application/gzip",  fg = "${theme.colors.red}" },
      { mime = "application/x-tar", fg = "${theme.colors.red}" },
      { mime = "application/x-xz",  fg = "${theme.colors.red}" },
      # Documents
      { mime = "application/pdf",   fg = "${theme.colors.orange}" },
      # Executables
      { name = "*.sh",  fg = "${theme.colors.green}" },
      { name = "*.nix", fg = "${theme.colors.blue}" },
      # Directories
      { name = "*/", fg = "${theme.colors.blue}", bold = true },
    ]
  '';
}
