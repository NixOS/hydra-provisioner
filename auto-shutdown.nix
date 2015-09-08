{ config, lib, ... }:

let timeout = 3600; in

{

  system.activationScripts.idle-monitor =
    ''
      touch /run/keep-alive
    '';

  systemd.services.idle-monitor =
    { description = "Idle Monitor";
      script = ''
        while true; do
          sleep 60
          if [ $(($(date +%s) - $(stat -c %Y /run/keep-alive))) -gt ${toString timeout} ]; then
            echo "powering off after ${toString timeout} seconds of idleness..."
            systemctl poweroff
          fi
        done
      '';
      serviceConfig.Restart = "always";
      wantedBy = [ "multi-user.target" ];
    };

}
