using GLib;

namespace Topbar {

  // ---------------- CPU Service --------------------
  public class CPUService : Object {

    private static CPUService ? instance = null;

    public string avg_cpu { get; private set; }
    public signal void updated ();

    public static CPUService get_default (uint interval_seconds = 10) {
      if (instance == null)
        instance = new CPUService (interval_seconds);
      return instance;
    }

    private CPUService (uint interval_seconds) {
      // Emit once immediately and then periodic
      update ();
      Timeout.add_seconds (interval_seconds, () => { update (); return true; });
    }

    private void update () {
      try {
        string contents;
        FileUtils.get_contents ("/proc/loadavg", out contents);

        // Format: 1min 5min 15min ...
        avg_cpu = contents.strip ().split (" ")[0];
        updated ();
      } catch (Error e) {
        // Ignore read failure
        warning ("Failed to parse %s", e.message);
      }
    }
  }

  // ---------------- Memory Service --------------------
  public class MemoryService : Object {

    private static MemoryService ? instance = null;

    public string total_gi { get; private set; }
    public string used_gi { get; private set; }
    public string available_gi { get; private set; }

    public signal void updated ();

    public static MemoryService get_default (uint interval_seconds = 2) {
      if (instance == null)
        instance = new MemoryService (interval_seconds);
      return instance;
    }

    private MemoryService (uint interval_seconds) {
      refresh ();
      Timeout.add_seconds (interval_seconds, () => { refresh (); return true; });
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

  // ---------------- CPU Temperature Service --------------------
  public class TemperatureService : Object {

    private static TemperatureService ? instance = null;

    public double temp_c { get; private set; }
    public signal void updated ();

    public static TemperatureService get_default (uint interval_seconds = 10) {
      if (instance == null)
        instance = new TemperatureService (interval_seconds);
      return instance;
    }

    private TemperatureService (uint interval_seconds) {
      refresh ();
      Timeout.add_seconds (interval_seconds, () => { refresh (); return true; });
    }

    private void refresh () {
      double ? t = read_x86_pkg_temp ();
      if (t == null)
        return;

      temp_c = t;
      updated ();
    }

    private double ? read_x86_pkg_temp () {
      try {
        var dir = File.new_for_path ("/sys/class/thermal");
        var enumerator = dir.enumerate_children (
          FileAttribute.STANDARD_NAME,
          FileQueryInfoFlags.NONE
        );

        FileInfo info;
        while ((info = enumerator.next_file ()) != null) {
          if (!info.get_name ().has_prefix ("thermal_zone"))
            continue;

          string basepath = "/sys/class/thermal/" + info.get_name ();
          string type_path = basepath + "/type";
          string temp_path = basepath + "/temp";

          string type;
          if (!FileUtils.get_contents (type_path, out type))
            continue;

          if (type.strip ().down () == "x86_pkg_temp") {
            string temp;
            if (FileUtils.get_contents (temp_path, out temp))
              return double.parse (temp.strip ()) / 1000.0;
          }
        }
      } catch (Error e) {
        warning ("Temp read error: %s", e.message);
      }

      return null;
    }
  }

  // ---------------- Root Usage Service --------------------
  public class DiskService : Object {

    private static DiskService ? instance = null;

    public string total_gi { get; private set; }
    public string used_gi { get; private set; }
    public string available_gi { get; private set; }

    public signal void updated ();

    public static DiskService get_default (uint interval_seconds = 15) {
      if (instance == null)
        instance = new DiskService (interval_seconds);
      return instance;
    }

    private DiskService (uint interval_seconds) {
      refresh ();
      Timeout.add_seconds (interval_seconds, () => { refresh (); return true; });
    }

    private void refresh () {
      try {
        var file = File.new_for_path ("/");
        var info = file.query_filesystem_info ("filesystem::size,filesystem::free", null);

        uint64 total = info.get_attribute_uint64 ("filesystem::size");
        uint64 avail = info.get_attribute_uint64 ("filesystem::free");

        total_gi = format_gi (total / 1024);
        available_gi = format_gi (avail / 1024);
        used_gi = format_gi ((total - avail) / 1024);

        updated ();
      } catch (Error e) {
        warning ("Disk service error: %s", e.message);
      }
    }

    private string format_gi (uint64 kb) {
      double gi = kb / (1024.0 * 1024.0);
      return "%.0fGi".printf (gi);
    }
  }
}
