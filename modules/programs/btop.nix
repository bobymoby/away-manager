{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.away.btop;

  serializeBool = v: if v then "True" else "False";

  serializeBtopValue =
    v:
    if builtins.isBool v then
      serializeBool v
    else if builtins.isInt v || builtins.isFloat v then
      builtins.toString v
    else if builtins.isString v then
      ''"${lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] v}"''
    else
      throw "away.btop.config: unsupported value type";

  btopConfText = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${k} = ${serializeBtopValue v}") cfg.config
  );
in
{
  options.away.btop = {
    enable = lib.mkEnableOption "Enable btop";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.btop;
      description = "The package to use for btop";
    };
    config = {
      color_theme = lib.mkOption {
        type = lib.types.str;
        default = "dracula.theme";
      };
      theme_background = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      truecolor = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      force_tty = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      presets = lib.mkOption {
        type = lib.types.str;
        default = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      };
      vim_keys = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      rounded_corners = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      graph_symbol = lib.mkOption {
        type = lib.types.str;
        default = "braille";
      };
      graph_symbol_cpu = lib.mkOption {
        type = lib.types.str;
        default = "default";
      };
      graph_symbol_gpu = lib.mkOption {
        type = lib.types.str;
        default = "default";
      };
      graph_symbol_mem = lib.mkOption {
        type = lib.types.str;
        default = "default";
      };
      graph_symbol_net = lib.mkOption {
        type = lib.types.str;
        default = "default";
      };
      graph_symbol_proc = lib.mkOption {
        type = lib.types.str;
        default = "default";
      };
      shown_boxes = lib.mkOption {
        type = lib.types.str;
        default = "proc cpu net mem gpu0";
      };
      update_ms = lib.mkOption {
        type = lib.types.int;
        default = 2000;
      };
      proc_sorting = lib.mkOption {
        type = lib.types.str;
        default = "cpu lazy";
      };
      proc_reversed = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_tree = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      proc_colors = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      proc_gradient = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_per_core = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_mem_bytes = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      proc_cpu_graphs = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      proc_info_smaps = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_left = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_filter_kernel = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      proc_aggregate = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      cpu_graph_upper = lib.mkOption {
        type = lib.types.str;
        default = "Auto";
      };
      cpu_graph_lower = lib.mkOption {
        type = lib.types.str;
        default = "Auto";
      };
      show_gpu_info = lib.mkOption {
        type = lib.types.str;
        default = "Auto";
      };
      cpu_invert_lower = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      cpu_single_graph = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      cpu_bottom = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      show_uptime = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      check_temp = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      cpu_sensor = lib.mkOption {
        type = lib.types.str;
        default = "Auto";
      };
      show_coretemp = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      cpu_core_map = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      temp_scale = lib.mkOption {
        type = lib.types.enum [
          "celsius"
          "fahrenheit"
          "kelvin"
          "rankine"
        ];
        default = "celsius";
      };
      base_10_sizes = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      show_cpu_freq = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      clock_format = lib.mkOption {
        type = lib.types.str;
        default = "%X";
      };
      background_update = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      custom_cpu_name = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      disks_filter = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      mem_graphs = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      mem_below_net = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      zfs_arc_cached = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      show_swap = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      swap_disk = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      show_disks = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      only_physical = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      use_fstab = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      zfs_hide_datasets = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      disk_free_priv = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      show_io_stat = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      io_mode = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      io_graph_combined = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      io_graph_speeds = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      net_download = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };
      net_upload = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };
      net_auto = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      net_sync = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      net_iface = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      show_battery = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      selected_battery = lib.mkOption {
        type = lib.types.str;
        default = "Auto";
      };
      show_battery_watts = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      log_level = lib.mkOption {
        type = lib.types.enum [
          "ERROR"
          "WARNING"
          "INFO"
          "DEBUG"
        ];
        default = "WARNING";
      };
      nvml_measure_pcie_speeds = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      gpu_mirror_graph = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      custom_gpu_name0 = lib.mkOption {
        type = lib.types.str;
        default = "Nvidia";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    away.packages = [ cfg.package ];
    away.file.".config/btop/btop.conf" = lib.mkDefault {
      text = btopConfText;
    };
  };
}
