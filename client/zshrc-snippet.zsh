# Add to ~/.zshrc on each machine you connect FROM. Replace my-starbase with the ssh name of the
# machine that runs tmux-starbase.

# When ssh ends, even on a dropped link, turn off the mouse reporting and alternate screen tmux
# enabled; otherwise mouse moves print garbage in this shell.
starbase() {
  ssh -t my-starbase starbase
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1049l\e[?25h'
}
