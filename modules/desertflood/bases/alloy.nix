{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.alloy =
    { config, ... }:
    let
      cfg = config;
      dfCfg = cfg.desertflood;
      alloyCfg = cfg.desertflood.services.prometheus.alloy;
      inherit (cfg.desertflood.hostInfo) hostName;
      ipAddress = dfCfg.globals.tailscaleIPs.${hostName};
    in
    {
      options = {
        desertflood.services.prometheus.alloy = {

          enable = lib.mkEnableOption {
            description = "Use Grafana Alloy to report system metrics";
          };

          loglevel = lib.mkOption {
            type = lib.types.enum [
              "warn"
              "debug"
              "info"
              "error"
            ];
            default = "warn";
            description = "Specify more or less logging about what alloy is doing";
          };

          livedebugging = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow live debugging of the components?";
          };

          loki_endpoint = lib.mkOption {
            type = lib.types.singleLineStr;
            default = null;
            description = "Where to send Loki logs";
          };

          prometheus_endpoint = lib.mkOption {
            type = lib.types.singleLineStr;
            default = null;
            description = "Where to send TSDB records";
          };

        };
      };

      config =
        let
          fragment = "alloy";
        in
        lib.mkMerge [
          {
            desertflood.services.prometheus.alloy.prometheus_endpoint =
              lib.mkDefault dfCfg.globals.endpoints.prometheus_write;

            desertflood.services.prometheus.alloy.loki_endpoint =
              lib.mkDefault dfCfg.globals.endpoints.loki_write;
          }
          (lib.mkIf alloyCfg.enable {

            services = {
              alloy = {
                enable = true;
                extraFlags = [
                  "--server.http.listen-addr=${ipAddress}:${builtins.toString dfCfg.globals.ports.alloy}"
                ];
              };

              # Necessary for the 'unix' exporter to read systemd data, when
              # alloy is running as a dynamic user
              # per https://discourse.nixos.org/t/systemd-exporter-couldnt-get-dbus-connection-read-unix-run-dbus-system-bus-socket-recvmsg-connection-reset-by-peer/64367
              # https://github.com/systemd/systemd/issues/22737
              # https://github.com/NixOS/nixpkgs/issues/408800
              dbus.implementation = "broker";
            };

            systemd.services.alloy.after = [ "tailscaled.service" ];

            environment.etc = {
              "${fragment}/config.alloy".text = # alloy
                ''
                  // For a full configuration reference, see https://grafana.com/docs/alloy
                  logging {
                  	level = "${alloyCfg.loglevel}"
                  }

                  loki.source.journal "default" {
                  	forward_to    = [loki.write.default.receiver]
                  	relabel_rules = loki.relabel.journal.rules
                  	max_age       = "5m"
                  	path          = "/var/log/journal"
                  	labels        = {component = "loki.source.journal", nodename = "${hostName}"}
                  }

                  loki.relabel "journal" {
                  	forward_to = []

                  	rule {
                  		source_labels = ["__journal__systemd_unit"]
                  		regex         = "^docker\\.service$"
                  		action        = "drop"
                  	}

                  	rule {
                  		source_labels = ["__journal__systemd_unit"]
                  		target_label  = "systemd_unit"
                  	}

                  	rule {
                  		source_labels = ["__journal__hostname"]
                  		target_label  = "systemd_hostname"
                  	}

                  	rule {
                  		source_labels = ["__journal__transport"]
                  		target_label  = "systemd_transport"
                  	}
                  }

                  loki.process "local" {
                  	forward_to = [loki.write.default.receiver]

                  	stage.drop {
                  		older_than = "16h"
                  	}
                  }

                  // This block relabels metrics coming from node_exporter to add standard labels
                  discovery.relabel "integrations_node_exporter" {
                  	targets = array.concat(
                  		prometheus.exporter.unix.node_exporter.targets,
                  		prometheus.exporter.self.internal.targets,
                  	)

                  	rule {
                  		target_label = "instance"
                  		replacement  = "${hostName}"
                  	}

                  	rule {
                  		target_label = "nodename"
                  		replacement  = "${hostName}"
                  	}

                  	rule {
                  		target_label = "job"
                  		replacement  = "node"
                  	}
                  }

                  prometheus.exporter.unix "node_exporter" {
                  	enable_collectors  = ["systemd", "processes"]
                  	disable_collectors = ["btrfs", "drbd", "fibrechannel", "infiniband", "mdadm", "nfs", "nfsd", "tapestats", "xfs", "zfs"]

                  	systemd {
                  		enable_restarts = true
                  	}

                  	filesystem {
                  		// Exclude filesystem types that aren't relevant for monitoring
                  		fs_types_exclude = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|tmpfs|fuse\\.unionfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"

                  		// Exclude mount points that aren't relevant for monitoring
                  		mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+|mnt/downloads|mnt/canto|mnt/seedbox)($|/)"

                  		// Timeout for filesystem operations
                  		mount_timeout = "5s"
                  	}

                  	netclass {
                  		// Ignore virtual and container network interfaces
                  		ignored_devices = "^(veth.*|cali.*|br-.*|docker.*|[a-f0-9]{15})$"
                  	}

                  	netdev {
                  		// Exclude virtual and container network interfaces from device metrics
                  		device_exclude = "^(veth.*|cali.*|br-.*|docker.*|[a-f0-9]{15})$"
                  	}
                  }

                  prometheus.exporter.self "internal" { }

                  prometheus.scrape "node_exporter" {
                  	scrape_interval = "15s"
                  	targets         = discovery.relabel.integrations_node_exporter.output

                  	forward_to = [prometheus.remote_write.default.receiver]
                  }

                  loki.write "default" {
                  	endpoint {
                  		url = "${alloyCfg.loki_endpoint}"
                  	}
                  }

                  prometheus.remote_write "default" {
                  	endpoint {
                  		url = "${alloyCfg.prometheus_endpoint}"
                  	}
                  }

                  livedebugging {
                  	enabled = ${if alloyCfg.livedebugging then "true" else "false"}
                  }
                '';
            };
          })
          (lib.mkIf (alloyCfg.enable && cfg.virtualisation.docker.enable) {
            systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "docker" ];

            environment.etc =
              let
                dockerSocket = "/run/docker.sock";
              in

              {
                "${fragment}/docker.alloy" = {
                  text = # alloy
                    ''
                      // Find all Docker targets
                      discovery.docker "local" {
                      	host = "unix://${dockerSocket}"
                      }

                      loki.source.docker "default" {
                      	forward_to    = [loki.process.local.receiver]
                      	relabel_rules = loki.relabel.docker.rules
                      	host          = "unix://${dockerSocket}"
                      	targets       = discovery.docker.local.targets
                      	labels        = {component = "loki.source.docker", nodename = "${hostName}"}
                      }

                      loki.relabel "docker" {
                      	forward_to = []

                      	rule {
                      		source_labels = ["__meta_docker_container_label_com_docker_compose_project"]
                      		target_label  = "docker_compose_project"
                      	}

                      	rule {
                      		source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
                      		target_label  = "docker_compose_service"
                      	}

                      	rule {
                      		source_labels = ["__meta_docker_container_label_org_opencontainers_image_title"]
                      		target_label  = "docker_image_title"
                      	}
                      }

                      // This block relabels metrics coming from cadvisor to add standard labels
                      discovery.relabel "integrations_cadvisor" {
                      	targets = prometheus.exporter.cadvisor.default.targets

                      	rule {
                      		target_label = "job"
                      		replacement  = "integrations/docker"
                      	}

                      	rule {
                      		target_label = "instance"
                      		replacement  = "${hostName}"
                      	}

                      	rule {
                      		target_label = "node"
                      		replacement  = "${hostName}"
                      	}

                      	rule {
                      		source_labels = ["container_label_com_docker_compose_service"]
                      		target_label  = "service"
                      	}

                      	rule {
                      		source_labels = ["name"]
                      		target_label  = "container"
                      	}
                      }

                      prometheus.exporter.cadvisor "default" {
                      	docker_host      = "unix://${dockerSocket}"
                      	docker_only      = true
                      	storage_duration = "5m"

                      	store_container_labels       = false
                      	allowlisted_container_labels = [
                      		"com.docker.compose.project",
                      		"com.docker.compose.service",
                      		"traefik.enable",
                      		"org.opencontainers.image.title",
                      		"org.opencontainers.image.version",
                      		"org.opencontainers.image.licenses",
                      	]
                      }

                      prometheus.scrape "cadvisor" {
                      	scrape_interval = "15s"
                      	targets         = discovery.relabel.integrations_cadvisor.output

                      	forward_to = [prometheus.relabel.cadvisor.receiver]
                      }

                      prometheus.relabel "cadvisor" {
                      	forward_to = [prometheus.remote_write.default.receiver]

                      	rule {
                      		source_labels = ["name"]
                      		target_label  = "container"
                      	}

                      	rule {
                      		source_labels = ["container_label_com_docker_compose_service"]
                      		target_label  = "service"
                      	}
                      }
                    '';
                };
              };
          })
        ];
    };
}
