namespace Topbar {

  public class Services : GLib.Object {

    public NiriIPC niri { get; construct; }

    public Services () throws Error {
      Object (niri: new NiriIPC ());
    }
  }
}
