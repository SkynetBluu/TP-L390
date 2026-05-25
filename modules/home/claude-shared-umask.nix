{ ... }: {
  # When nimbus is working inside ~/claude-projects/, drop umask to 002 so
  # files created here are group-writable (mode 664, dirs 775). The claude
  # sandbox user is in the `claude-shared` group; without this, files end up
  # 644 and claude can read but not modify them.
  #
  # Outside the shared trees, umask stays at 022 (default).

  programs.bash.initExtra = ''
    __claude_shared_umask() {
      case "$PWD" in
        "$HOME"/claude-projects/*|"$HOME"/claude-projects) umask 002 ;;
        *) umask 022 ;;
      esac
    }
    PROMPT_COMMAND="__claude_shared_umask''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  '';
}
