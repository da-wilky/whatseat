{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.services.whatseat-server;
  stateDir = "/var/lib/whatseat-server";
  environment = {
    WHATSEAT_DB = "${stateDir}/whatseat.sqlite";
  } // lib.optionalAttrs (cfg.publicUrl != null) { WHATSEAT_PUBLIC_URL = cfg.publicUrl; };
  # Runs as the service user, so files SQLite creates next to the database stay writable for the server.
  ctl = pkgs.writeShellScriptBin "whatseat-server-ctl" ''
    exec ${pkgs.util-linux}/bin/runuser -u whatseat-server -- ${pkgs.coreutils}/bin/env \
      ${lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}") environment)} \
      ${lib.getExe cfg.package} "$@"
  '';
in
{
  options.services.whatseat-server = {
    enable = lib.mkEnableOption "the WhatsEat backup server";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.whatseat-server;
      defaultText = lib.literalExpression "whatseat.packages.\${system}.whatseat-server";
    };
    listen = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8470";
      description = "Address to listen on. Serves plain HTTP; the app requires HTTPS, so put a TLS reverse proxy in front.";
    };
    clientIpHeader = lib.mkOption {
      type = lib.types.str;
      default = "X-Real-IP";
      description = ''
        Header the reverse proxy sets to the client's address, for the per-client registration limit.
        The proxy must overwrite it, e.g. nginx `proxy_set_header X-Real-IP $remote_addr;`; registration fails without it.
        Empty uses the connection's address, only right without a proxy.
      '';
    };
    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://backup.example.org";
      description = "Address as the app sees it. When set, `whatseat-server-ctl invite` also prints a link that fills in server and invite.";
    };
    inviteOnly = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Register only with a single-use invite from `sudo whatseat-server-ctl invite [-note TEXT] [validity, default 3d, e.g. 30m, 1h, 365d]`. maxAccounts then doesn't apply. Otherwise anyone reaching the server can register, up to maxAccounts.";
    };
    inactiveDays = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 365;
      description = "Delete accounts and their backups after this many days without a login. The app shows this value. 0 keeps them forever.";
    };
    purgeInterval = lib.mkOption {
      type = lib.types.str;
      default = "24h";
      example = "1h";
      description = "How often inactive accounts and expired invites are deleted (Go duration, e.g. 30m, 6h). Also runs once at startup.";
    };
    maxAccounts = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 100;
      description = "Accounts that may exist with open registration; once reached, it is closed. Ignored with inviteOnly.";
    };
    registerPerHour = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 10;
      description = "New accounts per hour and client address (IPv6 per /64), failed attempts included, so invites can't be guessed at speed either.";
    };
    maxBackups = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Backup files per account. The app keeps 7.";
    };
    maxBackupBytes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5 * 1024 * 1024;
      description = "Size limit per backup file.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.whatseat-server = {
      isSystemUser = true;
      group = "whatseat-server";
    };
    users.groups.whatseat-server = { };
    environment.systemPackages = [ ctl ];

    systemd.services.whatseat-server = {
      description = "WhatsEat backup server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = environment // {
        WHATSEAT_LISTEN = cfg.listen;
        WHATSEAT_INVITE_ONLY = lib.boolToString cfg.inviteOnly;
        WHATSEAT_INACTIVE_DAYS = toString cfg.inactiveDays;
        WHATSEAT_PURGE_INTERVAL = cfg.purgeInterval;
        WHATSEAT_MAX_ACCOUNTS = toString cfg.maxAccounts;
        WHATSEAT_MAX_BACKUPS = toString cfg.maxBackups;
        WHATSEAT_MAX_BACKUP_BYTES = toString cfg.maxBackupBytes;
        WHATSEAT_REGISTER_PER_HOUR = toString cfg.registerPerHour;
        WHATSEAT_CLIENT_IP_HEADER = cfg.clientIpHeader;
      };
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        User = "whatseat-server";
        Group = "whatseat-server";
        StateDirectory = "whatseat-server";
        StateDirectoryMode = "0700";
        UMask = "0077";
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];
      };
    };
  };
}
