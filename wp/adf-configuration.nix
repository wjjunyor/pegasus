{ config, pkgs, lib, inputs, options,  ... }: 

let

  app = "red";
  name = "adufms";
  domain = "${name}.org.br"  ;
  
in {

  security.acme = {
    certs."${app}.${domain}" = {
      # extraDomainNames = [ "*.${domain}" ];
      webroot = "/var/lib/acme/${app}.${domain}";
      group = "nginx";
    };
  };

  services = {
    wordpress = {
      webserver = "nginx";
      sites = {
        "${app}.${domain}" = {
          package = pkgs.wordpress6_4;
          database = {
            createLocally = true;
            name = "wordpress_adufms";
          };
          plugins = {
            inherit (pkgs.wordpressPackages.plugins)
              add-widget-after-content
              antispam-bee
              async-javascript
              breeze
              code-syntax-block
              co-authors-plus
              disable-xml-rpc
              jetpack
              jetpack-lite
              mailpoet
              opengraph
              simple-login-captcha
              simple-mastodon-verification
              webp-converter-for-media
              wp-gdpr-compliance
              wp-mail-smtp
              wp-statistics
              wp-user-avatars;
          };
          themes = with pkgs.wp4nix; 
          {
            inherit (pkgs.wordpressPackages.themes)
             twentytwentythree;
             # astra;
          };
          settings = {
            WP_DEFAULT_THEME = "twentytwentythree";
            WP_MAIL_FROM = "gcp-devops@wcbrpar.com";
            WPLANG = "pt_BR";
            AUTOMATIC_UPDATER_DISABLED = true;
          };
          poolConfig = {
            "pm" = "dynamic";
            "pm.max_children" = 64;
            "pm.max_requests" = 500;
            "pm.max_spare_servers" = 4;
            "pm.min_spare_servers" = 2;
            "pm.start_servers" = 2;
          };
          virtualHost ={
            robotsEntries = ''
              User-agent: *
              Disallow: /feed/
              Disallow: /trackback/
              Disallow: /wp-admin/
              Disallow: /wp-content/
              Disallow: /wp-includes/
              Disallow: /xmlrpc.php
              Disallow: /wp-
            '';
          };
        };
      };
    };
    nginx.virtualHosts = {
      
      "${app}.${domain}" = {
         useACMEHost = "${app}.${domain}";
         addSSL = true;
         locations."/.well-known/acme-challenge" = {
           root = "/var/lib/acme/${app}.${domain}";
         };
         locations."/" = {
           root = "/var/www/ADF";
           extraConfig = ''
             fastcgi_split_path_info ^(.+\.php)(/.+)$;
             fastcgi_pass unix:${config.services.phpfpm.pools."wordpress-${app}.${domain}".socket};
             include ${pkgs.nginx}/conf/fastcgi_params;
             include ${pkgs.nginx}/conf/fastcgi.conf;
           '';
         };
      };
      "${app}.${domain}80" = {
        serverName = "${app}.${domain}";
        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/${app}.${domain}";
          extraConfig = ''
            auth_basic off;
          '';
        };
        locations."/" = { return = "301 https://$host$request_uri"; };
      };
    };

  };
}
  



