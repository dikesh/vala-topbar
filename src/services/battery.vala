using GLib;

namespace Topbar {

  public class BatteryService : Object {

    private static BatteryService ? instance = null;

    public string battery_icon_name { get; private set; }
    public int percentage { get; private set; }
    private bool charging { get; private set; }

    public signal void updated ();

    private DBusProxy proxy;

    public static BatteryService get_default () throws Error {
      if (instance == null)
        instance = new BatteryService ();
      return instance;
    }

    private BatteryService () throws Error {
      proxy = find_battery_proxy ();
      refresh ();
      proxy.g_properties_changed.connect ((changed, invalidated) => refresh ());
    }

    private DBusProxy find_battery_proxy () throws Error {
      var upower = new DBusProxy.for_bus_sync (
        BusType.SYSTEM,
        DBusProxyFlags.NONE,
        null,
        "org.freedesktop.UPower",
        "/org/freedesktop/UPower",
        "org.freedesktop.UPower"
      );

      var devices = upower.call_sync ("EnumerateDevices", null, DBusCallFlags.NONE, -1);

      foreach (Variant v in devices.get_child_value (0)) {
        string path = v.get_string ();
        var p = new DBusProxy.for_bus_sync (
          BusType.SYSTEM,
          DBusProxyFlags.NONE,
          null,
          "org.freedesktop.UPower",
          path,
          "org.freedesktop.UPower.Device"
        );

        if (p.get_cached_property ("Type").get_uint32 () == 2) // Battery
          return p;
      }

      throw new IOError.NOT_FOUND ("No battery found");
    }

    private void refresh () {
      var state = proxy.get_cached_property ("State").get_uint32 ();
      var type = proxy.get_cached_property ("Type").get_uint32 ();

      double perc = proxy.get_cached_property ("Percentage").get_double () / 100.0;

      percentage = (int) (perc * 100);

      charging = (state == 4) || (state == 1); // FULLY_CHARGED or CHARGING
      bool is_battery = (type != 0) && (type != 1); // not UNKNOWN, not LINE_POWER

      if (!is_battery) {
        battery_icon_name = "battery-missing-symbolic";
      } else if (perc >= 0.95 && charging) {
        battery_icon_name = "battery-level-100-charged-symbolic";
      } else {
        string charge = charging ? "-charging" : "";
        int level = (int) Math.round (perc * 10) * 10;
        battery_icon_name = @"battery-level-$level$charge-symbolic";
      }

      updated ();
    }
  }
}
