{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.away.vim;

  isPlainAttrs = v: builtins.isAttrs v && !(lib.isDerivation v);

  toLua =
    value:
    if builtins.isBool value then
      if value then "true" else "false"
    else if builtins.isInt value || builtins.isFloat value then
      builtins.toString value
    else if builtins.isString value then
      builtins.toJSON value
    else if value == null then
      "nil"
    else
      throw "Unsupported value for Lua conversion: ${builtins.typeOf value}";

  flattenLuaAttrs =
    prefix: attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          path = if prefix == "" then name else "${prefix}.${name}";
        in
        if isPlainAttrs value then flattenLuaAttrs path value else [ { inherit path value; } ]
      ) attrs
    );

  renderLuaAssignments =
    attrs:
    lib.am.concatStringsNewLine (
      map (entry: "${entry.path} = ${toLua entry.value}") (flattenLuaAttrs "" attrs)
    );

  keymapsToLua =
    keymapList:
    lib.am.concatStringsNewLine (
      map (
        {
          mode,
          key,
          cmd,
        }:
        ''vim.keymap.set("${mode}", "${key}", "${cmd}")''
      ) keymapList
    );
in
{
  options.away.vim = {
    enable = lib.mkEnableOption "Enable vim";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "Vim package";
    };

    # configLua = lib.mkOption {
    #   type = lib.types.str;
    #   default = "";
    #   description = "Vim config file";
    # };

    # configVim = lib.mkOption {
    #   type = lib.types.str;
    #   default = "";
    #   description = "Vim config file";
    # };

    config = lib.mkOption {
      # type =
      #   with lib.types;
      #   attrsOf (oneOf [
      #     str
      #     bool
      #     int
      #     float
      #   ]);
      default = { };
    };

    keymap = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            mode = lib.mkOption { type = lib.types.str; };
            key = lib.mkOption { type = lib.types.str; };
            cmd = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
    };
    beforeLua = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    afterLua = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    away = {
      packages = [ cfg.package ];

      file.".config/nvim/init.lua".text = lib.am.concatStringsNewLine [
        cfg.beforeLua
        (renderLuaAssignments cfg.config)
        (keymapsToLua cfg.keymap)
        cfg.afterLua
      ];
      # file.".config/nvim/init.vim".text = cfg.configVim;
    };
  };
}
