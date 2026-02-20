using Gee;

namespace Topbar {

  // Constants
  const string BUS_NAME = "org.bluez";
  const string ADAPTER_PATH = "/org/bluez/hci0";

  public struct BluetoothDeviceInfo {
    public string name;
    public string icon;
  }

  public class BluetoothService : Object {

    private static BluetoothService ? instance = null;

    private DBusConnection ? bus;
    public bool powered = false;
    public string device_name;
    public string icon_name;

    public signal void updated ();

    public static BluetoothService get_default () {
      if (instance == null)instance = new BluetoothService ();
      return instance;
    }

    private BluetoothService () {
      init.begin ();
    }

    private async void init () {

      try {
        bus = yield Bus.get (BusType.SYSTEM);

        refresh.begin ();

        bus.signal_subscribe (
          BUS_NAME,
          "org.freedesktop.DBus.Properties",
          "PropertiesChanged",
          null,
          null,
          DBusSignalFlags.NONE,
          on_properties_changed
        );
      } catch (Error e) {
        warning ("Bluetooth init failed: %s", e.message);
      }
    }

    private async void refresh () {

      if (bus == null)return;

      try {
        var value = yield get_bt_property (ADAPTER_PATH, "Powered", "org.bluez.Adapter1");

        var prev_powered = powered;
        powered = value.get_boolean ();

        if (prev_powered != powered) {
          icon_name = powered ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic";
          updated ();
        }


        BluetoothDeviceInfo info = yield find_connected_device ();

        if (info.name != device_name) {

          device_name = info.name;
          icon_name = (device_name == "") ? "bluetooth-symbolic" : info.icon + "-symbolic";
          updated ();
        }
      } catch (Error e) {
        warning ("Bluetooth refresh failed: %s", e.message);
      }
    }

    private void on_properties_changed (DBusConnection conn,
                                        string ? sender,
                                        string object_path,
                                        string interface_name,
                                        string signal_name,
                                        Variant parameters) {
      // parameters structure = (s a{sv} as)

      string iface = parameters.get_child_value (0).get_string (null);
      if (iface == "org.bluez.Adapter1" || iface == "org.bluez.Device1")refresh.begin ();
    }

    private async ArrayList<string> get_device_paths () {

      var result = new ArrayList<string> ();

      try {

        Variant reply = yield bus.call (BUS_NAME,
                                        "/",
                                        "org.freedesktop.DBus.ObjectManager",
                                        "GetManagedObjects",
                                        null,
                                        new VariantType ("(a{oa{sa{sv}}})"),
                                        DBusCallFlags.NONE,
                                        -1);

        Variant objects = reply.get_child_value (0);

        for (size_t i = 0; i < objects.n_children (); i++) {
          Variant entry = objects.get_child_value (i);
          string path = entry.get_child_value (0).get_string (null);

          if (path.contains ("/dev_"))result.add (path);
        }
      } catch (Error e) {
        warning ("Device list failed: %s", e.message);
      }

      return result;
    }

    private async BluetoothDeviceInfo find_connected_device () {

      BluetoothDeviceInfo info = {};
      info.name = "";
      info.icon = "";

      var paths = yield get_device_paths ();

      foreach (string path in paths) {

        try {

          // Check Connected
          var value = yield get_bt_property (path, "Connected");

          if (!value.get_boolean ())continue;

          // Get Name
          value = yield get_bt_property (path, "Name");

          info.name = value.get_string (null);

          // Get Icon
          value = yield get_bt_property (path, "Icon");

          info.icon = value.get_string (null);

          return info;
        } catch (Error e) {
          warning ("Error: %s", e.message);
          continue;
        }
      }

      return info;
    }

    private async Variant get_bt_property (string path,
                                           string property,
                                           string iface = "org.bluez.Device1") throws Error {

      Variant reply = yield bus.call (BUS_NAME,
                                      path,
                                      "org.freedesktop.DBus.Properties",
                                      "Get",
                                      new Variant ("(ss)", iface, property),
                                      new VariantType ("(v)"),
                                      DBusCallFlags.NONE,
                                      -1);

      Variant value;
      reply.get ("(v)", out value);

      return value;
    }

    private async void set_enabled (bool state) {
      try {
        yield bus.call (BUS_NAME,
                        ADAPTER_PATH,
                        "org.freedesktop.DBus.Properties",
                        "Set",
                        new Variant ("(ssv)", "org.bluez.Adapter1", "Powered",
                                     new Variant.boolean (state)
                        ),
                        null,
                        DBusCallFlags.NONE,
                        -1);
      } catch (Error e) {
        warning ("Failed to set bluetooth power: %s", e.message);
      }
    }

    public void toggle_power () {
      set_enabled.begin (!powered);
    }
  }
}
