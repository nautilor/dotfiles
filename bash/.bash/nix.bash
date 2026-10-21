# Wrapper for classic nix-shell
nix-shell() {
  command nix-shell --command bash "$@"
}

# Wrapper for modern Nix CLI (nix develop)
nix() {
  if [[ "$1" == "develop" ]]; then
    shift
    command nix develop --command bash "$@"
  else
    command nix "$@"
  fi
}
