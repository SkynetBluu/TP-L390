# overlays/claude-code-latest.nix
# Claude Code - Latest prebuilt binary from npm
# Fetches native binary directly from @anthropic-ai/claude-code-linux-x64
#
# To update:
#   1. Check latest: npm view @anthropic-ai/claude-code version
#   2. Get hash:     nix-prefetch-url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-VERSION.tgz"
#   3. Convert:      nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and sha256 below

{ lib, fetchurl, claude-code, patchelf, glibc, stdenv, ... }:

let
  version = "2.1.123";
  sha256  = "sha256-QgMMl1BauBjTGxC/kqRYemcM2fEpBySoBeOV9tljaSw=";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${version}.tgz";
    inherit sha256;
  };

  sourceRoot = "package";

  nativeBuildInputs = [ patchelf ];

  dontAutoPatchelf = true;
  dontStrip        = true;

  installPhase = ''
    install -Dm755 claude $out/bin/claude
    patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $out/bin/claude
  '';

  meta = claude-code.meta // {
    description = "Claude Code - Anthropic's AI coding assistant (${version})";
    platforms   = [ "x86_64-linux" ];
  };
}
