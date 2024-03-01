{ config, pkgs, ... }:

let
  privateZeroTierInterfaces = [
  "ztr2qxf559" # vpn
  ];
  
  nginxModules = import <nixpkgs/nginx> { };

in

{
  nixpkgs.config.allowUnfree = true;

  # Networking set-up
  networking.hostName = "pegasus"; # Define your hostname.
  networking.nameservers = [ "84.200.69.80" "84.200.70.40" ]; # CloudFlare / DNS Watch
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP and HTTPS
  networking.firewall.trustedInterfaces = privateZeroTierInterfaces;
  networking.hostId = "141ec2b6"; # cut -c-8 </proc/sys/kernel/random/uuid

  # mDNS
  services.avahi.enable = true;
  services.avahi.allowInterfaces = privateZeroTierInterfaces;
  services.avahi.nssmdns = true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.domain = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;
  services.avahi.publish.workstation = true;

  # Open SSH
  services.openssh.enable = true;
  services.openssh.openFirewall = true; # SSH accessible on all interfaces
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
 
  # ZEROTIER
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [
  "abfd31bd47447701" # vpn                (PRIVATE)
  ];

}
