namespace Topbar {

  public class Utils {

    public static void run_script_async (string[] argv) {
      try {
        new Subprocess.newv (argv, SubprocessFlags.STDERR_SILENCE);
      } catch (Error e) {
        warning ("Failed to run script: %s", e.message);
      }
    }
  }
}
