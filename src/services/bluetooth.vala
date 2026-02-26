using Gee;

namespace Topbar {

  // Constants
  const string BUS_NAME = "org.bluez";
  const string ADAPTER_PATH = "/org/bluez/hci0";

  public class BluetoothDeviceInfo : Object {
    public string name;
    public string icon;

    public BluetoothDeviceInfo (string name = "", string icon = "") {
      this.name = name;
      this.icon = icon;
    }
  }

  public class BluetoothService : Object {

    private static BluetoothService ? instance = null;

    private DBusConnection ? bus;
    public bool powered = false;
    public HashMap<string, BluetoothDeviceInfo> devices;

    private bool needs_update = false;
    public signal void updated ();

    public static BluetoothService get_default () {
      if (instance == null)instance = new BluetoothService ();
      return instance;
    }

    private BluetoothService () {
      devices = new HashMap<string, BluetoothDeviceInfo>();
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

    /**
     * Property changed handler
     */
    private void on_properties_changed (DBusConnection conn,
                                        string ? sender,
                                        string object_path,
                                        string interface_name,
                                        string signal_name,
                                        Variant parameters) {
      // parameters structure = (s a{sv} as)
      string iface = parameters.get_child_value (0).get_string (null);

      if ((iface == "org.bluez.Adapter1" || iface == "org.bluez.Device1") && !needs_update) {
        needs_update = true;
        Timeout.add_once (50, () => {
          needs_update = false;
          refresh.begin ();
        });
      }
    }

    /**
     * Refresh
     */
    private async void refresh () {

      if (bus == null)return;

      try {
        // Check whether is powered
        var value = yield get_bt_property (ADAPTER_PATH, "Powered", "org.bluez.Adapter1");

        powered = value.get_boolean ();

        if (powered)yield set_connected_devices ();

        updated ();
      } catch (Error e) {
        warning ("Bluetooth refresh failed: %s", e.message);
      }
    }

    /**
     * Get Device paths
     */
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

          string[] parts = path.split ("/");
          if (parts.length == 5 && parts[4].has_prefix ("dev_"))result.add (path);
        }
      } catch (Error e) {
        warning ("Device list failed: %s", e.message);
      }

      return result;
    }

    /**
     * Set Connected devices
     */
    private async void set_connected_devices () {

      var paths = yield get_device_paths ();

      // Clear before setting new ones
      devices.clear ();

      foreach (var path in paths) {

        try {
          // Check Connected
          var value = yield get_bt_property (path, "Connected");

          if (!value.get_boolean ())continue;

          var device_info = new BluetoothDeviceInfo (path);

          // Get Name
          value = yield get_bt_property (path, "Name");

          device_info.name = value.get_string (null);

          // Get Icon
          value = yield get_bt_property (path, "Icon");

          device_info.icon = value.get_string (null) + "-symbolic";

          devices.set (path, device_info);
        } catch (Error e) {
          warning ("Error: %s", e.message);
          continue;
        }
      }
    }

    /**
     * Get Bluetooth Property
     */
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

    /**
     * Set Power with specified state
     */
    private async void set_power (bool state) {
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

    /**
     * Toggle power
     */
    public void toggle_power () {
      set_power.begin (!powered);
    }
  }
}
