namespace Topbar {

  public class Utils {

    private const string apps_relative_path = ".config/rofi/launchers/type-3/launcher.sh";
    private const string power_menu_relative_path = ".config/rofi/powermenu/type-5/powermenu.sh";

    private static string get_full_path (string relative_path) {
      return Path.build_filename (Environment.get_home_dir (), relative_path);
    }

    private static void run_script_async (string[] argv) {
      try {
        new Subprocess.newv (argv, SubprocessFlags.STDERR_SILENCE);
      } catch (Error e) {
        warning ("Failed to run script: %s", e.message);
      }
    }

    public static void launch_apps () {
      Utils.run_script_async ({ Utils.get_full_path (apps_relative_path) });
    }

    public static void launch_power_menu () {
      Utils.run_script_async ({ Utils.get_full_path (power_menu_relative_path) });
    }

    public static void launch_btop () {
      Utils.run_script_async ({ "kitty", "-e", "btop" });
    }
  }
}
