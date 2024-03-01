{ config, pkgs,  ... }:
{
  imports = 
    [ # External nixconf files.
      <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
      ./networking-configuration.nix
      ./webserving-configuration.nix
      ./wordpress-configuration.nix
      # ./wp4nix-configuration.nix
    ];
  # Supposedly better for the SSD.
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # Set your time zone.
  time.timeZone = "America/Campo_Grande";

  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "23.11"; # Did you read the comment?

  # Auto upgrade Always ON.
  system.autoUpgrade.enable = true;

  # Garbage Collection Automation and Disk Usage O  ^utimization
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 30d";
  nix.settings.auto-optimise-store = true;




}
