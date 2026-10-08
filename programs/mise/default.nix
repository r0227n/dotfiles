{ ... }:

{
  # mise is installed by Brewfile; versions are maintained in ordinary TOML.
  xdg.configFile."mise/config.toml".source = ./config.toml;
}
