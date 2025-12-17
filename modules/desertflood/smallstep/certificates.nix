{
  config,
  lib,
  ...
}:
# massively inspired by (or stolen from) the `acme` module in NixOS
# https://github.com/NixOS/nixpkgs/blob/1419cc5c5104185c444079d617096f788f0b2077/nixos/modules/security/acme/default.nix
#
# other useful docs:
# https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html
# https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
# https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
# https://nixos.org/manual/nixos/stable/#ch-running
# https://nixos.org/manual/nixos/stable/#module-security-acme
let
  flakeCfg = config;
  svcFolder = "/var/lib/smallstep";

  certForServiceModule =
    { name, ... }:
    {
      options = {
        serviceName = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Human-readable name for the service that will use the certificate.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "The group of the service that will need read access to the key.";
        };

        reloadServices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            The list of systemd services to call `systemctl try-reload-or-restart`
            on.
          '';
        };

        directory = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "serviceKeys/${name}/${name}.key";
          description = "Relative directory, under the certificate root, where the service-readable key is stored.";
        };
      };
    };

  certModule =
    { name, ... }:
    {
      options = {
        certName = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Human-readable name for the certificate.";
        };

        certPath = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${svcFolder}/certs/${name}/${name}.cert";
          description = "The certificate's path on disk.";
        };

        certRoot = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${svcFolder}/certs/${name}";
          description = "The certificate's path on disk.";
        };

        maxValidTime = lib.mkOption {
          type = lib.types.str;
          default = "24h";
          description = "Maximum length of time the certificate is valid for";
        };

        renewAt = lib.mkOption {
          type = lib.types.str;
          default = "10h";
          description = "When the certificate when this much time is left on the validity, or less.";
        };

        renewInterval = lib.mkOption {
          type = lib.types.str;
          default = "2/6:5:5"; # every 6 hours, 5 minutes and 5 seconds past the hour
          description = ''
            Systemd calendar expression when to check for renewal. See
            {manpage}`systemd.time(7)`.
          '';
        };

        extraDomainNames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = lib.literalExpression ''
            [
              "example.org"
              "mydomain.org"
            ]
          '';
          description = ''
            A list of extra domain names, which are included on the certificate to be issued.
            By default, each certificate includes:

            - networking.hostName
            - networking.fqdn
            - networking.hostName . networking.tailscaleDomain
            - 127.0.0.1
          '';
        };

        availableTo = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.submodule certForServiceModule);
          description = ''
            Attribute set of services that need access to the certificate's private key. For each service,
            creates `/var/run/smallstep/certs/''${cert}/serviceKeys/''${service}/''${service.key}` private key and makes it
            owned by smallstep:''${group}, with 0640 permissions on the private key and 0750 permissions
            on the folder.
          '';
          example = lib.literalExpression ''
            {
              "forgejo" = {
                group = "forgejo";
                reloadServices = [ "forgejo" ];
              };
              "node-exporter" = {
                group = "node-exporter";
                reloadServices = [ "prometheus-node-exporter" ];
              };
              prometheus = {
                group = "prometheus";
                reloadServices = [ "prometheus" ];
              };
            }
          '';
        };

      };
    };
in
{
  # /var/lib/smallstep
  # /var/lib/smallstep/keys
  # /var/lib/smallstep/certs
  #
  # generate certificates to /var/lib/smallstep/certs
  # generate private keys to /var/lib/smallstep/keys
  # the `keys` directory is 0600 root:root and each key is the same
  #
  # the `certs` directory is 0775 root:root and each certificate is the same
  #
  # create the certs
  # {hostName}
  # {fqdn}
  # {hostName}.{tailscaleDomain}
  # 127.0.0.1
  # any extra SANs provided by config
  #
  # need an option for SANs
  # need an option for groups
  # need an option for services to restart
  #
  # desertflood.step-ca.certificates = {
  #   <certificate> = {
  #     sans = [ listOf str ];
  #     groups = [ listOf str ];
  #     services = [ listOf str ];
  #   }
  # }
  config.flake.modules.nixos.smallstep =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixOScfg = config;
      stepCfg = config.desertflood.step-ca;

      commonServiceConfig = {
        Type = "oneshot";
        User = "smallstep";
        Group = lib.mkDefault "smallstep";
        UMask = "0022";
        StateDirectoryMode = "750";
        ProtectSystem = "strict";
        PrivateTmp = true;
        WorkingDirectory = "/tmp";
        CapabilityBoundingSet = [ "" ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          # 1. allow a reasonable set of syscalls
          "@system-service @resources"
          # 2. and deny unreasonable ones
          "~@privileged"
          # 3. then allow the required subset within denied groups
          "@chown"
        ];
      };

      commonSmallstepService = {
        after = [
          "network.target"
          "network-online.target"
          "nss-lookup.target"
        ];
        wants = [
          "network-online.target"
        ];
        path = [ pkgs.step-cli ];
        environment.STEPPATH = "/etc/step-ca";
        enableStrictShellChecks = true;
      };

      certToConfig =
        cert: data:
        let

          certFolderPath = "certs/${cert}";
          certificate = "certs/${cert}/${cert}.cert";
          certKeyFolder = "${certFolderPath}/certKey";
          certKey = "${certKeyFolder}/${cert}.key";
          certServiceKeysPath = "${certFolderPath}/serviceKeys";
          certServicePath = service: "${certServiceKeysPath}/${service}";
          certServiceKey = service: "${certServicePath service}/${service}.key";

          serviceFolders = [
            certFolderPath
            certServiceKeysPath
          ];

          servicesKeyFolders = lib.concatStringsSep " " (
            lib.mapAttrsToList (
              name: value: lib.escapeShellArg "${svcFolder}/${certServicePath name}"
            ) data.availableTo
          );
          # ++ lib.mapAttrsToList (name: value: "${certServicePath name}") data.availableTo;

          allServiceKeys = lib.mapAttrsToList (
            name: value: "${svcFolder}/${certServiceKey name}"
          ) data.availableTo;

          cleanCertificateAndKeys = lib.concatStringsSep "\n" (
            lib.map (key: "rm ${lib.escapeShellArg key}") allServiceKeys
            ++ [
              "rm ${lib.escapeShellArg certificate}"
              "rm ${lib.escapeShellArg certKey}"
            ]
          );

          copyServiceKeys = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              svcName: svcData:
              let
                srcKey = lib.escapeShellArg "${svcFolder}/${certKey}";
                escapedSvcPath = lib.escapeShellArg "${svcFolder}/${certServicePath svcName}";
              in
              # bash
              ''
                cp ${srcKey} ${lib.escapeShellArg "${svcFolder}/${certServiceKey svcName}"}
                chmod -R u=rwX,g=rX,o= ${escapedSvcPath}
              ''
            ) data.availableTo
          );

          chownServiceKeys = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              svcName: svcData:
              let
                escapedSvcPath = lib.escapeShellArg "${svcFolder}/${certServicePath svcName}";
              in
              # bash
              ''
                chown -R smallstep:${svcData.group} ${escapedSvcPath}
              ''
            ) data.availableTo
          );

          reloadServicesList = lib.mapAttrsToList (
            svcName: svcData: "${lib.escapeShellArg svcData.reloadServices}"
          ) data.availableTo;

          reloadServices = lib.optionalString (reloadServicesList != [ ]) (
            lib.concatStringsSep " " reloadServicesList
          );

          unitServiceFolders = [
            "smallstep"
            "smallstep/certs"
          ]
          ++ lib.map (path: "smallstep/${path}") serviceFolders;

          privilegedSetupScript =
            let
              certFile = lib.escapeShellArg certificate;
              keyFile = lib.escapeShellArg certKey;
            in
            pkgs.writeShellScriptBin "smallstep-pre-${cert}-privileged"
              # bash
              ''
                set -euo pipefail

                function check_expired {
                  if [[ -f ${certificate} ]]; then
                    if (step certificate ${lib.escapeShellArgs isExpiredOpts} 2>/dev/null); then
                      ${cleanCertificateAndKeys}
                    fi
                  fi
                }

                function set_perms {
                  chown smallstep:smallstep ${certFile} ${keyFile}
                  chmod u=rw,g=,o= ${keyFile}
                  chmod u=rw,g=rw,o=r ${certFile}
                }

                cd ${svcFolder} || exit 1
                mkdir --parents ${servicesKeyFolders} ${certKeyFolder}
                chown smallstep:smallstep ${servicesKeyFolders} ${certKeyFolder}
                chmod u=rwx,g=,o= ${certKeyFolder}
                ${if servicesKeyFolders != "" then "chmod u=rwx,g=rx,o= ${servicesKeyFolders}" else ""}


                # delete expired certificates & keys
                check_expired

                if [[ -f ${certificate} ]]; then
                  set_perms
                  exit 0
                fi

                # Recreate the certificate
                step ca certificate ${generateCmd}
                set_perms
                # Let smallstep own everything
                # chown -R smallstep:smallstep ${lib.escapeShellArg svcFolder}
              '';

          renewScript =
            pkgs.writeShellScriptBin "smallstep-order-renew-${cert}"
              # bash
              ''
                function check_renewal {
                  step certificate ${lib.escapeShellArgs needsRenewalOpts}
                  return $?
                }

                cd ${svcFolder} || exit 1

                if (check_renewal); then
                  step ca renew ${renewCmd}
                  touch ${svcFolder}/${certificate}.renewed
                fi

                ${copyServiceKeys}
              '';

          privilegedPostScript =
            pkgs.writeShellScriptBin "smallstep-post-${cert}-privileged"
              # bash
              ''
                set -euo pipefail

                cd ${svcFolder} || exit 1
                ${chownServiceKeys}
                if [ -f ${svcFolder}/${certificate}.renewed ]; then
                  ${
                    if reloadServices != "" then "systemctl --no-block try-reload-or-restart ${reloadServices}" else ""
                  }
                  rm ${svcFolder}/${certificate}.renewed
                fi
              '';

          stepOpts = [
            "--provisioner"
            "${flakeCfg.desertflood.step-ca.provisioner}"
          ]
          ++ [
            "--provisioner-password-file"
            "${nixOScfg.age.secrets.provisioner-password.path}"
          ]
          ++ [
            "--not-after"
            "${data.maxValidTime}"
          ]
          ++ [
            "--san"
            "${nixOScfg.networking.fqdn}"
            "--san"
            "${nixOScfg.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}"
            "--san"
            "127.0.0.1"
          ]
          ++ lib.concatMap (name: [
            "--san"
            name
          ]) data.extraDomainNames;

          stepArgs = [
            "${nixOScfg.networking.hostName}"
            certificate
            certKey
          ];

          checkStatusOpts = [
            "needs-renewal"
            certificate
            "--expires-in"
          ];

          isExpiredOpts = checkStatusOpts ++ [
            "0s"
          ];

          needsRenewalOpts = checkStatusOpts ++ [
            data.renewAt
          ];

          generateCmd = lib.escapeShellArgs (stepArgs ++ stepOpts);

          renewCmd = lib.escapeShellArgs [
            "--force"
            certificate
            certKey
          ];

        in
        {
          inherit (data) availableTo;

          renewTimer = {
            description = "Renew smallstep certificate for ${data.certName}";
            wantedBy = [ "timers.target" ];
            # Avoid triggering certificate renewals accidentally when running s-t-c.
            unitConfig."X-OnlyManualStart" = true;
            timerConfig = {
              OnCalendar = data.renewInterval;
              Unit = "smallstep-order-renew-${cert}.service";
              Persistent = "yes";
            };
          };

          orderRenewService = commonSmallstepService // {
            description = "Order (and renew!) smallstep certificate for ${cert}";

            wantedBy = [ "multi-user.target" ];

            unitConfig = {
              StartLimitIntervalSec = 0;
            };

            serviceConfig = commonServiceConfig // {
              StateDirectory = unitServiceFolders;

              StateDirectoryMode = "0755";
              UMask = "0077";

              RemainAfterExit = false;

              ExecStartPre = "+${privilegedSetupScript}/bin/smallstep-pre-${cert}-privileged";
              ExecStart = "${renewScript}/bin/smallstep-order-renew-${cert}";
              ExecStartPost = "+${privilegedPostScript}/bin/smallstep-post-${cert}-privileged";
            };
          };

          certInfo = {
            cert_file = "${svcFolder}/${certificate}";
            key_file = lib.mapAttrs' (
              svcName: svcData: lib.nameValuePair svcName "${svcFolder}/${certServiceKey svcName}"
            ) data.availableTo;
          };
        };

      certConfigs = lib.mapAttrs certToConfig stepCfg.certs;
    in
    {
      options = {
        desertflood.step-ca.certs = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.submodule certModule);
          description = ''
            Certificates to create using `step ca certificate` commands. This will
            create a service that generates the certificates, a service to renew each
            certificate and a timer to periodically run the renewal service.
          '';
        };

        desertflood.step-ca.certInfo = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.anything;
          description = "Information about the generated certificates";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (stepCfg.certs != { }) {
          users.users.smallstep = {
            home = "${svcFolder}";
            homeMode = "755";
            group = "smallstep";
            isSystemUser = true;
          };

          users.groups.smallstep = { };

          systemd.services =
            let
              orderRenewServices = lib.mapAttrs' (
                cert: conf: lib.nameValuePair "smallstep-order-renew-${cert}" conf.orderRenewService
              ) certConfigs;
            in
            orderRenewServices;

          systemd.timers = lib.mapAttrs' (
            cert: conf: lib.nameValuePair "smallstep-renew-${cert}" conf.renewTimer
          ) certConfigs;

          desertflood.step-ca.certInfo = lib.mapAttrs' (
            cert: conf: lib.nameValuePair cert conf.certInfo
          ) certConfigs;
        })
      ];
    };

}
