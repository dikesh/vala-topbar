namespace Topbar {

  public class BarLeft : Gtk.Box {

    public BarLeft () {
      Object (spacing: 8);
      append (new Apps ());
    }
  }
}
