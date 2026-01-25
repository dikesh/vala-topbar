using Gtk;

namespace Topbar {

  public class App : Gtk.Application {

    public App() {
      Object(application_id: "com.arch.Topbar");
    }

    public override void activate() {
      try {
        // Init Niri events
        var events = new Topbar.NiriEvents();

        // Application window for each monitor
        var model = Gdk.Display.get_default().get_monitors();
        for (var i = 0; i < model.get_n_items(); i++)
          new Bar(this, (Gdk.Monitor) model.get_item(i), events).present();
      } catch (Error e) {
        critical("Niri Events Exception");
      }
    }
  }
}
