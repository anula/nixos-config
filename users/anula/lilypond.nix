#
# Music notation: LilyPond plus editing support for it in neovim.
#

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lilypond
  ];

  programs.nixvim = {
    # Syntax highlighting, compiling with errors in the quickfix list, PDF
    # viewing and MIDI playback for .ly files.
    # https://github.com/martineausimon/nvim-lilypond-suite
    extraPlugins = [ pkgs.vimPlugins.nvim-lilypond-suite ];
    extraConfigLua = ''
      require('nvls').setup({})
    '';
  };
}
