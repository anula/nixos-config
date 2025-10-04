{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kdePackages.kalgebra
    kdePackages.kcalc
  ];
}
