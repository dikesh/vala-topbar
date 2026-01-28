using GLib;

namespace Topbar {

  // ---------------- CPU Service --------------------
  public class CPUService : Object {
    // 1-minute load average
    public signal void updated (string load1);

    private uint interval;
    private string last_load;

    public CPUService (uint interval_seconds = 10) {
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

  // ---------------- Memory Service --------------------
  public class MemoryService : Object {

    public string total_gi { get; private set; }
    public string used_gi { get; private set; }
    public string available_gi { get; private set; }

    public signal void updated ();

    public MemoryService (uint interval_seconds = 2) {
      refresh ();
      Timeout.add_seconds (interval_seconds, () => {
        refresh ();
        return true;
      });
    }

    private void refresh () {
      try {
        string contents;
        FileUtils.get_contents ("/proc/meminfo", out contents);

        uint64 total = 0;
        uint64 avail = 0;

        foreach (var line in contents.split ("\n")) {
          if (line.has_prefix ("MemTotal:"))
            total = parse_kb (line);
          else if (line.has_prefix ("MemAvailable:"))
            avail = parse_kb (line);
        }

        total_gi = format_gi (total);
        available_gi = format_gi (avail);
        used_gi = format_gi (total - avail);

        updated ();
      } catch (Error e) {
        warning ("RAM service error: %s", e.message);
      }
    }

    private uint64 parse_kb (string line) {
      var parts = line.split (" ");
      foreach (var p in parts) {
        if (p.strip ().length > 0 && p[0].isdigit ())
          return uint64.parse (p);
      }
      return 0;
    }

    private string format_gi (uint64 kb) {
      double gi = kb / (1024.0 * 1024.0);
      return "%.1fGi".printf (gi);
    }
  }
}
