{ config, pkgs, lib, ... }:

{
  # TLS using ACME
  security.acme = {
    acceptTerms = true;
    defaults.email = "gcp-devops@wcbrpar.com";

    certs."wcbrpar.com" = {
      webroot = "/var/lib/acme/wcbrpar.com";
      email = "gcp-devops@wcbrpar.com";
      # Ensure that the web server you use can read the generated certs
      # Take a look at the group option for the web server you choose.
      group = "nginx";
      # Since we have a wildcard vhost to handle port 80,
      # we can generate certs for anything!
      # Just make sure your DNS resolves them.
      extraDomainNames = [ "walcor.com.br" "redcom.digital" ];
    };
  };

  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.users.nginx.extraGroups = [ "acme" ];

  # Nginx webserver
  services.nginx = {
    enable = true;
    logError = "stderr info";
    
    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    # Log real IPs behind CDNs
    commonHttpConfig =

    let

      realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
      fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
      cfipv4 = fileToList (pkgs.fetchurl {
        url = "https://www.cloudflare.com/ips-v4";
        sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
      });
      cfipv6 = fileToList (pkgs.fetchurl {
        url = "https://www.cloudflare.com/ips-v6";
        sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
      });

    in

      ''
        ${realIpsFromList cfipv4}
        ${realIpsFromList cfipv6}
        real_ip_header CF-Connecting-IP;
      '';
    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
        https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;
  
      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';
      
      # Disable embedding as a frame
      add_header X-Frame-Options DENY;
  
      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    clientMaxBodySize = "20M";

    virtualHosts = {
    
      "wcbrpar.com" = {
        default = true;
        # forceSSL = true; 
        addSSL = true;
        useACMEHost = "wcbrpar.com";
        # Catchall vhost, will redirect users to HTTPS for all vhosts
        # All serverAliases will be added as extra domain names on the certificate.
        serverAliases = [ "*.wcbrpar.com" ];
        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/wcbrpar.com";
        };
        locations."/" = {
          root = "/var/www/WPR";
            extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools."wcbrpar.com".socket};
              include ${pkgs.nginx}/conf/fastcgi_params;
              include ${pkgs.nginx}/conf/fastcgi.conf;
            '';
        };
        locations."/" = {
          proxyPass = "http://localhost:8096";
	};
      };
    
      "wcbrpar.com80" = {
        serverName = "wcbrpar.com";
        serverAliases = [ "*.wcbrpar.com" ];
        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/wcbrpar.com";
          extraConfig = ''
            auth_basic off;
          '';
        };
        locations."/" = { return = "301 https://$host$request_uri"; };
        listen = [ { addr = "0.0.0.0"; port = 80; } { addr = "[::0]"; port = 80; } ];
      };
    };
  };
  
  services.phpfpm.pools."wcbrpar.com" = {
    user  = "nginx";
    group  = "nginx";
    settings = {
      "listen.owner" = config.services.nginx.user;
      "listen.group" = config.services.nginx.group;
      "listen.mode" = "0600";
      "pm" = "dynamic";
      "pm.max_children" = 75;
      "pm.start_servers" = 10;
      "pm.min_spare_servers" = 5;
      "pm.max_spare_servers" = 20;
      "pm.max_requests" = 500;
      "catch_workers_output" = 1;
    };
    phpOptions  = ''
      upload_max_filesize = 128M
      post_max_size = 20M
      memory_limit = 256M
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

}

