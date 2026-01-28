using GLib;
namespace Topbar {


  public class AvgCPU : Object {
    // 1-minute load average
    public signal void updated (string load1);

    private uint interval;
    private string last_load;

    public AvgCPU (uint interval_seconds = 10) {
      interval = interval_seconds;

      // Emit once immediately and then periodic
      update ();
      Timeout.add_seconds (interval, () => { update (); return true; });
    }

    private void update () {
      try {
        string contents;
        FileUtils.get_contents ("/proc/loadavg", out contents);

        // Format: 1min 5min 15min ...
        last_load = contents.strip ().split (" ")[0];
        updated (last_load);
      } catch (Error e) {
        // Ignore read failure
        warning ("Failed to parse %s", e.message);
      }
    }

    // Getter
    public string current () { return last_load; }
  }
}
