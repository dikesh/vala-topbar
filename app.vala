using Gtk;

namespace Topbar {

  public class App : Gtk.Application {

    public App() {
      Object(application_id: "com.arch.Topbar");
    }

    public override void activate() {
      // Application window
      new Bar(this).present();
    }
  }
}
