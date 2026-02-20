namespace  Topbar {

  public class VolumeService : Object {

    private static VolumeService ? instance = null;
    private DataInputStream ? stream;

    public int level;
    public string icon_name;
    private bool is_muted;

    private bool needs_update = false;
    public signal void updated (int level, string icon_name);

    public static VolumeService get_default () {
      if (instance == null)instance = new VolumeService ();
      return instance;
    }

    private VolumeService () {
      try {
        // Init string values
        icon_name = get_icon ();

        var proc = new Subprocess.newv (
          { "pw-dump", "--monitor" },
          SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
        );

        stream = new DataInputStream (proc.get_stdout_pipe ());
        listen.begin ();
      } catch (Error e) {
        warning ("Failed to subscribe wpctl: %s", e.message);
      }
    }

    private async void listen () {
      try {
        string ? line;

        while (true) {
          line = yield stream.read_line_async ();

          if (line == null)return;

          if (("Audio/Device" in line || "PipeWire:Interface:Metadata" in line) && !needs_update) {
            needs_update = true;
            Timeout.add_once (50, () => {
              needs_update = false;
              handle_change.begin ();
            });
          }
        }
      } catch (Error e) {
        warning ("Read line error: %s", e.message);
      }
    }

    private async void handle_change (bool show_vol_osd = false) {
      try {
        var output = yield Utils.run_script ({ "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" });

        if (output == null || !("Volume:" in output))return;

        var prev_level = level;
        var prev_is_muted = is_muted;

        level = (int) (100 * float.parse (output.strip ().split (" ")[1]));
        is_muted = "MUTED" in output;
        icon_name = get_icon ();

        if (prev_level != level || prev_is_muted != is_muted) {
          updated (level, icon_name);
          if (show_vol_osd)VolumeOSD.get_default ().show_volume (level, icon_name);
        }
      } catch (Error e) {
        warning ("Error: %s", e.message);
      }
    }

    public async void update_volume_level (bool increase, bool show_vol_osd = false) {
      try {
        var change = increase ? "5%+" : "5%-";
        yield Utils.run_script ({ "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", change });

        handle_change.begin (show_vol_osd);
      } catch (Error e) {
        print ("Failed to change volume level: %s", e.message);
      }
    }

    public async void toggle_volume_mute (bool show_vol_osd = false) {
      try {
        yield Utils.run_script ({ "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" });

        handle_change.begin (show_vol_osd);
      } catch (Error e) {
        print ("Failed to toggle volume mute: %s", e.message);
      }
    }

    private string get_icon () {
      if (is_muted)return "audio-volume-muted-symbolic";
      if (level >= 66)return "audio-volume-high-symbolic";
      if (level >= 33)return "audio-volume-medium-symbolic";
      return "audio-volume-low-symbolic";
    }
  }
}
