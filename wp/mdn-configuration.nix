{ config, pkgs, lib, inputs, options,  ... }: 

let

  app = "red";
  name = "marcosdan";
  domain = "${name}.com.br"  ;
  
in {

  security.acme = {
    certs."${domain}" = {
      extraDomainNames = [ "${app}.${domain}" ];
      webroot = "/var/lib/acme/${app}.${domain}";
      group = "nginx";
    };
  };

  services = {
    phpfpm.pools."wordpress-${app}.${domain}".phpOptions  = ''
      upload_max_filesize = 128M
      post_max_size = 20M
      memory_limit = 256M
      '';
    wordpress = {
      webserver = "nginx";
      sites = {
        "${app}.${domain}" = {
          package = pkgs.wordpress6_4;
          database = {
            createLocally = true;
            name = "wordpress_${name}";
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
              static-mail-sender-configurator
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
          languages = [ pkgs.wordpressPackages.languages.pt_BR ];
          settings = {
            WP_DEFAULT_THEME = "twentytwentythree";
            WP_MAIL_FROM = "gcp-devops@wcbrpar.com";
            WP_SITEURL = "http://red.marcosdan.com.br";
            WP_HOME = "http://red.marcosdan.com.br";            
            WPLANG = "pt_BR";
            AUTOMATIC_UPDATER_DISABLED = true;
            FORCE_SSL_ADMIN = true;
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
            addSSL = true;
            
          };
        };
      };
    };
    nginx.virtualHosts = {
      
      "${app}.${domain}" = {
         useACMEHost = "${domain}";
         addSSL = true;
         locations."/.well-known/acme-challenge" = {
           root = "/var/lib/acme/${app}.${domain}";
         };
         locations."/" = {
           root = "/var/www/MDN";
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
  



