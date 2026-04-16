{ pkgs, ... }:

{
  # 3D Printing software.
  environment.systemPackages = with pkgs; [
    prusa-slicer
  ];
}
