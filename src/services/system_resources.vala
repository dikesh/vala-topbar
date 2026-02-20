namespace Topbar {

  // ---------------- CPU Service --------------------
  public class CPUService : Object {

    private static CPUService ? instance = null;

    public string avg_cpu { get; private set; }
    public signal void updated ();

    public static CPUService get_default (uint interval_seconds = 10) {
      if (instance == null)instance = new CPUService (interval_seconds);
      return instance;
    }

    private CPUService (uint interval_seconds) {
      // Emit once immediately and then periodic
      update.begin ();
      Timeout.add_seconds (interval_seconds, () => { update.begin (); return true; });
    }

    private async void update () {
      try {
        var contents = yield Utils.get_file_contents_async ("/proc/loadavg");

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
      if (instance == null)instance = new MemoryService (interval_seconds);
      return instance;
    }

    private MemoryService (uint interval_seconds) {
      refresh.begin ();
      Timeout.add_seconds (interval_seconds, () => { refresh.begin (); return true; });
    }

    private async void refresh () {
      try {
        uint64 total = 0, avail = 0;
        var contents = yield Utils.get_file_contents_async ("/proc/meminfo");

        foreach (var line in  contents.split ("\n")) {
          if (line.has_prefix ("MemTotal:"))total = parse_kb (line);
          else if (line.has_prefix ("MemAvailable:"))avail = parse_kb (line);
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

    private string temp_path;
    public double temp_c { get; private set; }
    public signal void updated ();

    public static TemperatureService get_default (uint interval_seconds = 10) {
      if (instance == null)instance = new TemperatureService (interval_seconds);
      return instance;
    }

    private TemperatureService (uint interval_seconds) {
      refresh.begin ();
      Timeout.add_seconds (interval_seconds, () => { refresh.begin (); return true; });
    }

    private async void refresh () {
      double ? t = yield read_x86_pkg_temp ();

      if (t == null)return;

      temp_c = t;
      updated ();
    }

    private async string ? get_x86_pkg_temp_path () {
      try {
        var dir = File.new_for_path ("/sys/class/thermal");
        var enumerator = yield dir.enumerate_children_async (FileAttribute.STANDARD_NAME,
                                                             FileQueryInfoFlags.NONE);

        FileInfo info;
        while ((info = enumerator.next_file ()) != null) {
          if (!info.get_name ().has_prefix ("thermal_zone"))continue;

          string basepath = "/sys/class/thermal/" + info.get_name ();
          string type_path = basepath + "/type";
          string temp_path = basepath + "/temp";

          var type = yield Utils.get_file_contents_async (type_path);

          if (type.strip ().down () == "x86_pkg_temp")return temp_path;
        }
      } catch (Error e) {
        warning ("Temp read error: %s", e.message);
      }

      return null;
    }

    private async double ? read_x86_pkg_temp () {
      try {
        if (temp_path == null)temp_path = yield get_x86_pkg_temp_path ();
        if (temp_path == null)return null;

        uint8[] contents;
        var file = File.new_for_path (temp_path);
        yield file.load_contents_async (null, out contents, null);

        return double.parse (((string) contents).strip ()) / 1000.0;
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
      if (instance == null)instance = new DiskService (interval_seconds);
      return instance;
    }

    private DiskService (uint interval_seconds) {
      refresh.begin ();
      Timeout.add_seconds (interval_seconds, () => { refresh.begin (); return true; });
    }

    private async void refresh () {
      try {
        var file = File.new_for_path ("/");
        var info = yield file.query_filesystem_info_async ("filesystem::size,filesystem::free",
                                                           Priority.DEFAULT);

        uint64 total = info.get_attribute_uint64 ("filesystem::size");
        uint64 avail = info.get_attribute_uint64 ("filesystem::free");

        var curr_available_gi = format_gi (avail / 1024);
        if (available_gi == curr_available_gi)return;

        total_gi = format_gi (total / 1024);
        available_gi = curr_available_gi;
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
