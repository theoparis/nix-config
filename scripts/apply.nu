#!/run/current-system/sw/bin/nu
nixos-rebuild switch --flake .#
stow -t ~/ dotfiles
