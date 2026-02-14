namespace  Topbar {

  public class VolumeService : Object {

    private static VolumeService ? instance = null;
    private DataInputStream ? stream;

    public int level;
    public string icon_name;

    public signal void updated (int level, string icon_name);

    public static VolumeService get_default () {
      if (instance == null)instance = new VolumeService ();
      return instance;
    }

    private VolumeService () {
      try {
        handle_change ();

        var proc = new Subprocess.newv (
          { "pw-mon", "-Noap" },
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

          if (line != null && line.strip () == "changed:")handle_change ();
        }
      } catch (Error e) {
        warning ("Subscribe error: %s", e.message);
      }
    }

    private void handle_change () {
      try {
        string output;
        Process.spawn_command_line_sync ("wpctl get-volume @DEFAULT_AUDIO_SINK@", out output);
        level = (int) (100 * float.parse (output.strip ().split (" ")[1]));

        if ("MUTED" in output)icon_name = "audio-volume-muted";
        else if (level >= 66)icon_name = "audio-volume-high-symbolic";
        else if (level >= 33)icon_name = "audio-volume-medium-symbolic";
        else icon_name = "audio-volume-low-symbolic";

        updated (level, icon_name);
      } catch (SpawnError e) {
        warning ("Spawn error: %s", e.message);
      }
    }

    public void update_volume_level (bool increase) {
      var change = increase ? "5%+" : "5%-";
      Utils.run_script_async ({ "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", change });
    }

    public void toggle_volume_mute () {
      Utils.run_script_async ({ "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" });
    }
  }
}
