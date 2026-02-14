using NM;

namespace Topbar {

  public class WifiService : GLib.Object {

    private static WifiService ? instance = null;

    private NM.Client client;
    public string ssid;
    public string icon_name;

    private AccessPoint ? subscribed_ap = null;
    private ulong ? ap_strength_handler_id = null;
    public signal void updated ();

    public static WifiService get_default () {
      if (instance == null)instance = new WifiService ();
      return instance;
    }

    private WifiService () {
      try {
        client = new NM.Client ();

        update ();
        client.notify.connect (() => update ());
        client.device_added.connect (() => updated ());
        client.device_removed.connect (() => updated ());
      } catch (Error err) {
        warning ("Nerwork manager failed: %s", err.message);
      }
    }

    private void update () {
      var found_wifi = false;

      client.get_active_connections ().foreach (active_conn => {

        active_conn.get_devices ().foreach (device => {
          if (!(device is NM.DeviceWifi))return;
          found_wifi = true;

          var wifi = (NM.DeviceWifi) device;
          var ap = wifi.get_active_access_point ();

          if (ap != null) {
            ssid = (string) ap.get_ssid ().get_data ();
            icon_name = active_conn.state ==
                        ActiveConnectionState.ACTIVATING ? "network-wireless-acquiring-symbolic" :
                        get_icon (ap.get_strength ());

            // Unsubscribe / subscribe AP strength
            if (subscribed_ap != null && ap_strength_handler_id != null && ap != subscribed_ap)
              unsubscribe_ap_strength ();
            if (subscribed_ap == null && ap_strength_handler_id == null)subscribe_ap_strength (ap);
          } else {
            ssid = "";
            icon_name = "network-wireless-offline-symbolic";
          }
          updated ();
        });
      });

      if (!found_wifi) {
        if (subscribed_ap != null && ap_strength_handler_id != null)unsubscribe_ap_strength ();
        ssid = "";
        icon_name = "network-wireless-offline-symbolic";
        updated ();
      }
    }

    private void subscribe_ap_strength (AccessPoint ap) {
      subscribed_ap = ap;
      ap_strength_handler_id = ap.notify["strength"].connect (() => {
        icon_name = get_icon (ap.get_strength ());
        updated ();
      });
    }

    private void unsubscribe_ap_strength () {
      subscribed_ap.disconnect (ap_strength_handler_id);
      subscribed_ap = null;
      ap_strength_handler_id = null;
    }

    private string get_icon (uint8 strength) {
      if (strength > 80)return "network-wireless-signal-excellent-symbolic";
      if (strength > 60)return "network-wireless-signal-good-symbolic";
      if (strength > 40)return "network-wireless-signal-ok-symbolic";
      if (strength > 20)return "network-wireless-signal-weak-symbolic";
      return "network-wireless-signal-none-symbolic";
    }
  }
}
