using GLib;

int main (string[] args) {

  if (args.length < 2)return 0;

  try {
    var conn = new SocketClient ().connect (
      new UnixSocketAddress (Environment.get_user_runtime_dir () + "/topbar.sock"),
      null
    );

    var output = conn.get_output_stream ();
    output.write_all ((args[1] + "\n").data, null);
  } catch (Error e) {
    stderr.printf ("IPC failed: %s\n", e.message);
  }

  return 0;
}
