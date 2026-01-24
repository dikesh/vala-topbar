using GLib;
using Json;

namespace Topbar {

  public class NiriEvents : GLib.Object {

    private Subprocess proc;
    private DataInputStream input;

    public signal void event_received (Json.Object event);

    public NiriEvents () throws Error {
      proc = new Subprocess.newv (
                                  { "niri", "msg", "--json", "event-stream" },
                                  SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE
      );

      input = new DataInputStream (proc.get_stdout_pipe ());

      start_reader ();
    }

    private void start_reader () {
      new Thread<void> ("niri-event-stream", () => {
        try {
          while (true) {
            string? line = input.read_line (null);
            if (line == null)
              break;

            var parser = new Json.Parser ();
            parser.load_from_data (line, -1);

            var obj = parser.get_root ().get_object ();

            // Hop back to GTK main loop
            Idle.add (() => {
              event_received (obj);
              return false;
            });
          }
        } catch (Error e) {
          warning ("niri event stream stopped: %s", e.message);
        }
      });
    }
  }
}
