{ lib, config, ... }:

{
  options.away = {
    gen-dir = lib.mkOption {
      type = lib.types.str;
      default = "${config.away.home}/.away-manager";
      description = "The directory where the away-manager files are stored";
    };
    profile-dir = lib.mkOption {
      type = lib.types.str;
      default = "${config.away.home}/.away-manager-profile";
      description = "The directory where the away-manager profile files are stored";
    };
    shell-rc = lib.mkOption {
      type = lib.types.str;
      default = "${config.away.home}/.bashrc";
      description = "Shell rc file location";
    };
    shell-rc-path-command = lib.mkOption {
      type = lib.types.str;
      default = ''export PATH="${config.away.profile-dir}/bin:$PATH"'';
      description = "Shell rc file location";
    };
  };
}
