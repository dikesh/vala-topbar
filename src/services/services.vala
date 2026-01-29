namespace Topbar {

  public class Services : GLib.Object {

    public NiriIPC niri { get; construct; }
    public CPUService avg_cpu { get; construct; }
    public MemoryService memory { get; construct; }
    public TemperatureService temperature { get; construct; }
    public DiskService disk_usage { get; construct; }

    public Services () throws Error {
      Object (
              niri: new NiriIPC (),
              avg_cpu: new CPUService (),
              memory: new MemoryService (),
              temperature: new TemperatureService (),
              disk_usage: new DiskService ()
      );
    }
  }
}
