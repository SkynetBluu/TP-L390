# modules/home/mpv.nix
# mpv video player — configured for YouTube, yt-dlp, and Wayland

{ config, pkgs, lib, ... }:

let
  # ── Scripts ───────────────────────────────────────────────────────────────

  # Helper script for yts fzf preview
  yt-preview = pkgs.writeShellScriptBin "yt-preview" ''
    ID="$1"
    FILE="$2"
    # yt-dlp outputs NDJSON (one object per line), not a JSON array
    # Use grep+jq to find the matching entry
    ${pkgs.gnugrep}/bin/grep "\"id\":\"$ID\"" "$FILE" | \
    ${pkgs.jq}/bin/jq -r '
      "Title:    " + .title + "\n" +
      "Channel:  " + (.channel // "Unknown") + "\n" +
      "Duration: " + (.duration_string // "?") + "\n" +
      "Views:    " + ((.view_count // 0) | tostring) + "\n" +
      "Upload:   " + (.upload_date // "?") + "\n\n" +
      (.description // "No description" | .[0:400])
    ' 2>/dev/null || echo "No preview available"
  '';

  # Interactive YouTube search and play via fzf
  yt-search = pkgs.writeShellScriptBin "yt-search" ''
    set -euo pipefail
    if [ -z "''${1:-}" ]; then
      echo "Usage: yt-search <query>"
      exit 1
    fi

    QUERY="$*"
    echo "🔍 Searching YouTube for: $QUERY"

    RESULTS=$(${pkgs.yt-dlp}/bin/yt-dlp \
      "ytsearch10:$QUERY" \
      --flat-playlist \
      --dump-json \
      --no-warnings \
      --quiet 2>/dev/null)

    if [ -z "$RESULTS" ]; then
      echo "No results found."
      exit 1
    fi

    RESULTS_FILE=$(mktemp /tmp/yts-XXXX.json)
    echo "$RESULTS" > "$RESULTS_FILE"
    trap "rm -f $RESULTS_FILE" EXIT

    FORMATTED=$(echo "$RESULTS" | ${pkgs.jq}/bin/jq -r \
      '"\(.id)\t\(.title) [\(.duration_string // "?")]  \(.channel // "Unknown")"')

    SELECTED=$(echo "$FORMATTED" | \
      ${pkgs.fzf}/bin/fzf \
        --delimiter='\t' \
        --with-nth=2 \
        --prompt="▶ " \
        --header="YouTube Search: $QUERY  (Enter to play, Ctrl+C to cancel)" \
        --preview="${yt-preview}/bin/yt-preview {1} $RESULTS_FILE" \
        --preview-window=right:45%:wrap \
        --height=80%) || exit 0

    VIDEO_ID=$(echo "$SELECTED" | cut -f1)
    VIDEO_TITLE=$(echo "$SELECTED" | cut -f2)

    echo "▶ Playing: $VIDEO_TITLE"
    ${pkgs.mpv}/bin/mpv "https://www.youtube.com/watch?v=$VIDEO_ID"
  '';

  # Play YouTube playlist interactively
  yt-playlist = pkgs.writeShellScriptBin "yt-playlist" ''
    set -euo pipefail
    if [ -z "''${1:-}" ]; then
      echo "Usage: yt-playlist <playlist-url>"
      exit 1
    fi

    URL="$1"
    echo "📋 Loading playlist..."

    RESULTS=$(${pkgs.yt-dlp}/bin/yt-dlp \
      "$URL" \
      --flat-playlist \
      --dump-json \
      --no-warnings \
      --quiet 2>/dev/null)

    FORMATTED=$(echo "$RESULTS" | ${pkgs.jq}/bin/jq -r \
      '"\(.id)\t\(.title) [\(.duration_string // "?")]"')

    SELECTED=$(echo "$FORMATTED" | \
      ${pkgs.fzf}/bin/fzf \
        --multi \
        --delimiter='\t' \
        --with-nth=2 \
        --prompt="▶ " \
        --header="Select videos (Tab for multi-select, Enter to play)" \
        --height=60%) || exit 0

    echo "$SELECTED" | cut -f1 | while read -r id; do
      ${pkgs.mpv}/bin/mpv "https://www.youtube.com/watch?v=$id"
    done
  '';

  # Download with quality selection
  yt-download = pkgs.writeShellScriptBin "yt-download" ''
    set -euo pipefail
    if [ -z "''${1:-}" ]; then
      echo "Usage: yt-download <url> [video|audio|best]"
      exit 1
    fi

    URL="$1"
    MODE="''${2:-video}"

    case "$MODE" in
      audio|mp3|a)
        echo "🎵 Downloading audio..."
        ${pkgs.yt-dlp}/bin/yt-dlp \
          --extract-audio \
          --audio-format mp3 \
          --audio-quality 0 \
          --embed-thumbnail \
          --embed-metadata \
          --output "$HOME/Music/%(uploader)s/%(title)s.%(ext)s" \
          "$URL"
        ;;
      best|4k|b)
        echo "📹 Downloading best quality video..."
        ${pkgs.yt-dlp}/bin/yt-dlp \
          --format "bestvideo+bestaudio/best" \
          --merge-output-format mkv \
          --embed-thumbnail \
          --embed-metadata \
          --output "$HOME/Videos/%(uploader)s/%(title)s.%(ext)s" \
          "$URL"
        ;;
      video|v|*)
        echo "📹 Downloading video (1080p)..."
        ${pkgs.yt-dlp}/bin/yt-dlp \
          --format "bestvideo[height<=1080]+bestaudio/best[height<=1080]" \
          --merge-output-format mp4 \
          --embed-thumbnail \
          --embed-metadata \
          --output "$HOME/Videos/%(uploader)s/%(title)s.%(ext)s" \
          "$URL"
        ;;
    esac

    echo "✓ Done!"
  '';

  # Watch later queue
  yt-queue = pkgs.writeShellScriptBin "yt-queue" ''
    set -euo pipefail
    QUEUE_FILE="$HOME/.local/share/yt-queue.txt"
    mkdir -p "$(dirname "$QUEUE_FILE")"

    case "''${1:-play}" in
      add|a)
        if [ -z "''${2:-}" ]; then echo "Usage: yt-queue add <url>"; exit 1; fi
        echo "$2" >> "$QUEUE_FILE"
        echo "✓ Added to queue ($(wc -l < "$QUEUE_FILE") items)"
        ;;
      list|l)
        if [ ! -s "$QUEUE_FILE" ]; then echo "Queue is empty"; exit 0; fi
        cat -n "$QUEUE_FILE"
        ;;
      play|p)
        if [ ! -s "$QUEUE_FILE" ]; then echo "Queue is empty"; exit 0; fi
        echo "▶ Playing queue ($(wc -l < "$QUEUE_FILE") items)..."
        ${pkgs.mpv}/bin/mpv --playlist="$QUEUE_FILE"
        ;;
      clear|c)
        > "$QUEUE_FILE"
        echo "✓ Queue cleared"
        ;;
      *)
        echo "Usage: yt-queue [add <url>|list|play|clear]"
        ;;
    esac
  '';

  # Quick clip — play a specific time range from a URL
  yt-clip = pkgs.writeShellScriptBin "yt-clip" ''
    set -euo pipefail
    if [ -z "''${3:-}" ]; then
      echo "Usage: yt-clip <url> <start> <end>"
      echo "Example: yt-clip 'https://youtube.com/...' 1:30 2:45"
      exit 1
    fi
    ${pkgs.mpv}/bin/mpv \
      --start="$2" \
      --end="$3" \
      "$1"
  '';

in
{
  # ── mpv ───────────────────────────────────────────────────────────────────

  programs.mpv = {
    enable = true;

    config = {
      # ── Video ──────────────────────────────────────────────────────────
      profile          = "gpu-hq";
      vo               = "gpu";
      gpu-api          = "opengl";       # Intel UHD 620 — opengl more stable than vulkan
      hwdec            = "vaapi";        # VA-API hardware decode
      hwdec-codecs     = "all";

      # ── Audio ──────────────────────────────────────────────────────────
      ao               = "pipewire";
      volume           = 100;
      volume-max       = 150;

      # ── Subtitles ──────────────────────────────────────────────────────
      sub-auto         = "fuzzy";
      sub-font         = "JetBrainsMono Nerd Font";
      sub-font-size    = 44;
      sub-color        = "#cdd6f4";      # Catppuccin foreground
      sub-border-color = "#1e1e2e";      # Catppuccin background
      sub-border-size  = 2;
      sub-shadow-offset = 1;

      # ── UI ─────────────────────────────────────────────────────────────
      osc              = true;
      osd-font         = "JetBrainsMono Nerd Font";
      osd-font-size    = 32;
      osd-color        = "#cdd6f4";
      osd-border-color = "#1e1e2e";
      osd-bar-align-y  = -1;            # OSD bar at bottom
      osd-bar-h        = 2;

      # ── Window ─────────────────────────────────────────────────────────
      keep-open        = true;           # Don't close on end
      autofit-larger   = "90%x90%";     # Max window size
      geometry         = "50%+50%+50%"; # Centre on screen

      # ── Screenshots ────────────────────────────────────────────────────
      screenshot-format    = "png";
      screenshot-directory = "~/Pictures/mpv";
      screenshot-template  = "%F-%P";

      # ── Cache ──────────────────────────────────────────────────────────
      cache            = true;
      demuxer-max-bytes = "50MiB";
      demuxer-max-back-bytes = "25MiB";

      # ── YouTube / yt-dlp ───────────────────────────────────────────────
      ytdl             = true;
      ytdl-format      = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
      ytdl-raw-options = "sub-langs=en,compat-options=no-youtube-channel-redirect";
    };

    # Key bindings
    bindings = {
      # Volume
      "WHEEL_UP"   = "add volume 2";
      "WHEEL_DOWN" = "add volume -2";

      # Speed
      "["          = "add speed -0.25";
      "]"          = "add speed 0.25";
      "{"          = "add speed -0.5";
      "}"          = "add speed 0.5";
      "BS"         = "set speed 1.0";

      # Seeking
      "LEFT"       = "seek -5";
      "RIGHT"      = "seek 5";
      "UP"         = "seek 60";
      "DOWN"       = "seek -60";
      "Shift+LEFT" = "seek -1 exact";
      "Shift+RIGHT" = "seek 1 exact";

      # Chapters
      "PGUP"       = "add chapter -1";
      "PGDWN"      = "add chapter 1";

      # Subtitles
      "v"          = "cycle sub-visibility";
      "V"          = "cycle sub";

      # Audio tracks
      "a"          = "cycle audio";

      # Screenshot
      "s"          = "screenshot video";
      "S"          = "screenshot window";

      # Loop
      "l"          = "ab-loop";
      "L"          = "set loop-file inf";

      # Quality (for YouTube)
      "q"          = ''cycle-values ytdl-format "bestvideo[height<=480]+bestaudio" "bestvideo[height<=720]+bestaudio" "bestvideo[height<=1080]+bestaudio"'';
    };

    profiles = {
      # Fast profile for slow connections
      "fast" = {
        ytdl-format = "bestvideo[height<=480]+bestaudio/best[height<=480]";
        hwdec       = "vaapi";
      };
      # Audio-only profile
      "audio-only" = {
        video        = "no";
        ytdl-format  = "bestaudio/best";
        ao           = "pipewire";
      };
      # Full HD
      "hd" = {
        ytdl-format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
      };
    };
  };

  # ── Scripts and packages ──────────────────────────────────────────────────

  home.packages = [
    yt-preview
    yt-search
    yt-playlist
    yt-download
    yt-queue
    yt-clip
    pkgs.yt-dlp
    pkgs.yewtube
  ];

  # ── Shell aliases ─────────────────────────────────────────────────────────

  programs.bash.shellAliases = {
    yts     = "yt-search";                              # Search YouTube with fzf
    ytp     = "mpv";                                    # Play URL directly in mpv
    ytd     = "yt-download";                            # Download video
    ytmp3   = "yt-download '' audio";                  # Download audio
    ytq     = "yt-queue";                               # Queue manager
    ytc     = "yt-clip";                                # Play clip
    ytmusic = "mpv --profile=audio-only";              # Audio-only playback
    ytbg    = "mpv --profile=audio-only --no-video &"; # Play audio in background
  };
}
