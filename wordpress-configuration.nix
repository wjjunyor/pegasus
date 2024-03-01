{ pkgs, ... }:
{

  imports = 
  [ # Wordpress Conf for RED Clients
  # ./wp/adf-configuration.nix
  ./wp/mdn-configuration.nix
  ];

  environment.systemPackages = with pkgs; [ wp4nix php ];
  environment.variables.WP_VERSION = "6.4"; 

  nixpkgs.overlays = [ (self: super:
    wordpressPackages {
      src = builtins.fetchGit {
        url = "https://git.helsinki.tools/helsinki-systems/wp4nix";
        ref = "master";
      };
    }
  )];

}
