{
  pkgs,
  lib,
  config,
  ...
}:
{
  away = {
    assertions = [
      {
        assertion = true;
        message = "Always true";
      }
    ];

    username = "bobymoby";
    file = {
      ".file" = {
        source = ./file;
      };
      ".config/folder3" = {
        source = ./folder;
        recursive = true;
      };
      ".my-symlink".source = lib.am.mkOutOfStoreSymlink "${config.away.home}/some/target";
      ".text-file" = {
        text = "echo 'asd'";
        executable = true;
      };
    };

    packages = with pkgs; [
      gcc
    ];

    btop.enable = true;
    btop.config.color_theme = "ayu.theme";

    vim = {
      enable = true;
      config = {
        vim.opt.number = true;
        vim.opt.relativenumber = true;
        vim.opt.tabstop = 4;
        vim.opt.shiftwidth = 4;
        vim.opt.expandtab = true;
        vim.opt.smartindent = true;
        vim.opt.wrap = false;
        vim.opt.termguicolors = true;
        vim.opt.cursorline = true;
      };
      keymap = [
        {
          mode = "n";
          key = "<leader>w";
          cmd = "<cmd>w<CR>";
        }
      ];
      # beforeLua = "before";
      # afterLua = "after";
    };

    script-extensions = {
      beforeActivation = [ "echo before" ];
      afterActivation = [ "echo after" ];
    };

    env-variables = {
      "MYKEY" = "MY-VALUE";
    };
  };
}
