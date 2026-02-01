namespace Topbar {

  public class ScreenRecordService : GLib.Object {

    private static ScreenRecordService ? instance = null;

    private static string filename;

    private bool is_recording = false;
    public signal void recording_toggled (bool reccording);

    public static ScreenRecordService get_default () {
      if (instance == null)
        instance = new ScreenRecordService ();
      return instance;
    }

    private ScreenRecordService () {
      recording_toggled.connect (is_recording => { this.is_recording = is_recording; });
    }

    private async void start_recording () {
      // Toggle Recording
      recording_toggled (true);

      var now = new DateTime.now_local ().format ("%Y%m%d%H%M%S");
      filename = Utils.get_full_path (@"Videos/screenrec-$now.mp4");

      try {
        var subprocess = new Subprocess.newv (
          { "/bin/sh", "-c", "wl-screenrec -g \"$(slurp)\" -f " + filename },
          SubprocessFlags.STDOUT_SILENCE | SubprocessFlags.STDERR_PIPE
        );

        Bytes stderr;
        yield subprocess.communicate_async (null, null, null, out stderr);

        if (subprocess.get_exit_status () != 0) {
          recording_toggled (false);
        }
      } catch (Error e) {
        warning ("Failed to run script: %s", e.message);
        recording_toggled (false);
      }
    }

    private void stop_recording () {
      Utils.run_script_async ({ "pkill", "wl-screenrec" });
      recording_toggled (false);
      Utils.run_script_async ({ "notify-send", "Screen Recorder ..", @"Filename: $filename" });
    }

    public void toggle_recording () {
      if (is_recording)stop_recording ();
      else start_recording.begin ();
    }
  }
}
