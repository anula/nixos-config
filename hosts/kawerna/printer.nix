
{ pkgs, ... }:

{
  # Printer
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];
  # Scanner
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];
}
