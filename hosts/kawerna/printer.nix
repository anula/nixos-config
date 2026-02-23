{ pkgs, ... }:

{
  # Enable CUPS for printing.
  services.printing.enable = true;

  # Avahi is essential for discovering IPP Everywhere printers and
  # eSCL scanners.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Scanner configuration using eSCL (driverless scanning).
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  # Grant 'anula' user access to printing and scanning on this host.
  users.users.anula.extraGroups = [ "lp" "scanner" ];
}
