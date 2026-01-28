namespace Topbar {

  public class Services : GLib.Object {

    public NiriIPC niri { get; construct; }
    public AvgCPU avg_cpu { get; construct; }

    public Services () throws Error {
      Object (niri: new NiriIPC (), avg_cpu: new AvgCPU ());
    }
  }
}
