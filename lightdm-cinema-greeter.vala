/**
 * project:     gtk-based greeter for lightdm, that runs on armbian
 * author:      movinator@github.com
 * created:     14.06.2021
 * copyright:   2021 movinator@github.com - all rights reserved
 *              published according to GPL-V3 (see LICENSE)
 */
using Gtk;

const string GETTEXT_PACKAGE = "lightdm-cinema-greeter";
public class Config
{
  public string domain          { get; private set; }
  public string prefix          { get; private set; }
  public string locale          { get; private set; }
  public string uiResource      { get; private set; }
  public string backgroundImage { get; private set; }
  public string imgSession1     { get; private set; }
  public string imgSession2     { get; private set; }
  public string imgReboot       { get; private set; }
  public string imgPowerOff     { get; private set; }
  public string imgUser         { get; private set; }
  public string? kSession1      { get; private set; }
  public string? kSession2      { get; private set; }


  string shared(string what) {
    string s = @"$prefix/share/$domain/$what";

    return s;
    }


  string sharedUI() {
    string n = @"$domain.ui";

    return shared(n);
    }


  string i18n() {
    string s = @"$prefix/share/locale";

    return s;
    }


  public Config(string _prefix, string _domain) {
    domain     = _domain;
    prefix     = _prefix;
    locale     = i18n();
    uiResource = sharedUI();
    /* Initialize i18n */
    Intl.setlocale(LocaleCategory.ALL, "de_DE.UTF-8");
    Intl.bindtextdomain(domain, locale);
    Intl.bind_textdomain_codeset(domain, "UTF-8");
    Intl.textdomain(domain);

    backgroundImage = shared("planet_omega-wallpaper-1920x1200.jpg");
    imgSession1 = shared("xbmc.png");
    imgSession2 = shared("Xfce.png");
    imgReboot   = shared("reset.png");
    imgPowerOff = shared("powerOff.png");
    imgUser     = shared("avatar-default.png");

    foreach (var s in LightDM.get_sessions()) {
            if (s.key.has_prefix("kodi")) {
               kSession1 = s.key;
               }
            else if (s.key.has_prefix("lightdm")) {
               kSession2 = s.key;
               }
            }
    }
  }


public class Cache
{
  public string? lastUser;
  public string language;
  public int session;
  string fileName;


  public Cache(Config config) {
    fileName = "/var/lib/lightdm/" + config.domain + "/.cache";
    language = "de_DE.UTF-8";
    session  = 99;
    read();
    }


  void read() {
    var file = File.new_for_path(fileName);

    if (file.query_exists()) {
       message("cache file found\n");
       try {
           var dis = new DataInputStream(file.read());
           string line;

           while ((line = dis.read_line(null)) != null) {
                 string[] parts = line.split(" = ", 2);
                 switch (parts[0].strip()) {
                   case "lastUser":
                        lastUser = parts[1].strip();
                        message("cached user is \"%s\"\n", lastUser);
                        break;
                   case "language":
                        language = parts[1].strip();
                        message("cached language is \"%s\"\n", language);
                        break;
                   case "session":
                        session = int.parse(parts[1]);
                        message("cached session is #%d\n", session);
                        break;
                   }
                 }
           }
       catch (Error e) {
           error("error reading cache file: %s", e.message);
           }
       }
    }


  public void flush() {
    var file = File.new_for_path(fileName);
    try {
        if (file.query_exists()) {
           file.delete();
           }
        var dos  = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));

        dos.put_string("lastUser = " + lastUser + "\n");
        dos.put_string("language = " + language + "\n");
        dos.put_string("session  = " + session.to_string()  + "\n");
        }
    catch (Error e) {
        error("failed to write cache: %s\n", e.message);
        }
    }
  }


public class Handler
{
  public Handler(Widgets widgets, CinemaGreeter greeter) {
    widgets.window1.destroy.connect(()
            => { Gtk.main_quit(); });
    widgets.btSession1.clicked.connect(()
            => { message("Left Login button clicked. Login to session #1\n");
                 greeter.start_session(1); });
    widgets.btSession2.clicked.connect(()
            => { message("Right Login button clicked. Login to session #2\n");
                 greeter.start_session(2); });
    widgets.btReboot.clicked.connect(()
            => { greeter.reboot(); });
    widgets.btPowerOff.clicked.connect(()
            => { greeter.powerOff(); });
    widgets.ePass.activate.connect(()
            => { message("ENTER in password field detected. Login again to last session\n");
                 greeter.start_session(0); });
    }
  }


public class Widgets
{
  public Image backgroundImage { get; private set; }
  public Image imgSession1 { get; private set; }
  public Image imgSession2 { get; private set; }
  public Image imgReboot   { get; private set; }
  public Image imgPowerOff { get; private set; }
  public Image imgUsr      { get; private set; }
  public Window window1    { get; private set; }
  public Overlay overlay   { get; private set; }
  public Entry eUsr        { get; private set; }
  public Entry ePass       { get; private set; }
  public Label lUsr        { get; private set; }
  public Label lPass       { get; private set; }
  public Label lMsg        { get; private set; }
  public Label lDate       { get; private set; }
  public Label lTime       { get; private set; }
  public Box boxLogin      { get; private set; }
  public Button btSession1 { get; private set; }
  public Button btSession2 { get; private set; }
  public Button btReboot   { get; private set; }
  public Button btPowerOff { get; private set; }


  public Widgets(Builder builder, Config config) {
    window1  = builder.get_object("window1") as Window;
    overlay  = builder.get_object("overlay") as Overlay;
    boxLogin = builder.get_object("bxBigLogin") as Box;
    backgroundImage = builder.get_object("bgImg") as Image;
    imgSession1 = builder.get_object("imgSession1") as Image;
    imgSession2 = builder.get_object("imgSession2") as Image;
    imgReboot   = builder.get_object("imgReboot")   as Image;
    imgPowerOff = builder.get_object("imgPowerOff") as Image;
    imgUsr      = builder.get_object("imgUsr")      as Image;
    btSession1  = builder.get_object("btSession1")  as Button;
    if (config.kSession1 == null) {
       btSession1.set_sensitive(false);
       }
    btSession2  = builder.get_object("btSession2")  as Button;
    if (config.kSession2 == null) {
       btSession2.set_sensitive(false);
       }
    btReboot    = builder.get_object("btReboot")    as Button;
    btPowerOff  = builder.get_object("btPowerOff")  as Button;
    eUsr        = builder.get_object("eUsr")        as Entry;
    ePass       = builder.get_object("ePass")       as Entry;
    lUsr        = builder.get_object("lUsr")        as Label;
    lPass       = builder.get_object("lPass")       as Label;
    lMsg        = builder.get_object("lMsg")        as Label;
    lDate       = builder.get_object("lDate")       as Label;
    lTime       = builder.get_object("lTime")       as Label;
    setup(config);
    }


  public void setup(Config config) {
    backgroundImage.set_from_file(config.backgroundImage);
    imgSession1.set_from_file(config.imgSession1);
    imgSession2.set_from_file(config.imgSession2);
    imgReboot.set_from_file(config.imgReboot);
    imgPowerOff.set_from_file(config.imgPowerOff);
    imgUsr.set_from_file(config.imgUser);
    var now = new DateTime.now_local();

    lDate.set_text(now.format("%x"));
    lTime.set_text(now.format("%X"));
    Pango.FontDescription pfd = Pango.FontDescription.from_string("Dejavu Sans Bold 20");

    lUsr.override_font(pfd);
    lPass.override_font(pfd);
    lMsg.override_font(pfd);
    eUsr.override_font(pfd);
    ePass.override_font(pfd);
    pfd = Pango.FontDescription.from_string("Dejavu Sans 40");

    lDate.override_font(pfd);
    pfd = Pango.FontDescription.from_string("Dejavu Sans Bold 55");

    lTime.override_font(pfd);
    }
  }


public class CinemaGreeter
{
  public static CinemaGreeter instance;
  private LightDM.Greeter greeter;
  private Widgets widgets;
  private Config config;
  private Cache cache;
  private int requestedSession;


  public CinemaGreeter() {
    if (instance == null) {
       config  = new Config("/usr", GETTEXT_PACKAGE);
       cache   = new Cache(config);
       var builder = new Builder();

       try {
           builder.add_from_file(config.uiResource);
           }
       catch (Error e) {
           error("failed to load file: %s", e.message);
           }
       widgets = new Widgets(builder, config);
       new Handler(widgets, this);
       widgets.overlay.add_overlay(widgets.boxLogin);
       var connected = false;

       try {
           greeter  = new LightDM.Greeter();
           greeter.show_message.connect((text, type)  => { show_message(text, type); });
           greeter.show_prompt.connect((text, type)   => { show_prompt(text, type); });
           greeter.authentication_complete.connect(() => { authentication_complete(); });

           connected = greeter.connect_to_daemon_sync();
           }
       catch (Error e) {
           warning("failed to connect to lightDM daemon: %s", e.message);
           }
       if (!connected) Posix.exit(Posix.EXIT_FAILURE);
       GLib.Environment.set_variable("GDK_CORE_DEVICE_EVENTS", "1", true);
       GLib.Environment.set_variable("G_MESSAGES_DEBUG", "all", true);
       Gdk.get_default_root_window().set_cursor(new Gdk.Cursor.for_display(Gdk.Display.get_default(), Gdk.CursorType.LEFT_PTR));

       if (cache.lastUser != null) {
          widgets.eUsr.set_text(cache.lastUser);
          widgets.ePass.grab_focus();
          }
       else {
          widgets.eUsr.set_text("");
          widgets.eUsr.grab_focus();
          }
       instance = this;
       }
    Timeout.add(1000, updateTime);
    instance.widgets.overlay.show_all();
    instance.widgets.window1.show_all();
    }


  private bool updateTime() {
    var now = new DateTime.now_local();

    instance.widgets.lTime.set_text(now.format("%X"));
    return true;
    }


  public void start_session(int session) {
    message("request to start session with id #%d\n", session);
    instance.widgets.eUsr.set_sensitive(false);
    instance.widgets.ePass.set_sensitive(false);
    requestedSession = session;
    if (instance.greeter.get_in_authentication()) {
       try {
           instance.greeter.cancel_authentication();
           }
       catch (Error e) {
           error("authentication failed: %s\n", e.message);
           }
       }
    string userName = instance.widgets.eUsr.get_text();
    bool   rv       = false;

    message("start authentication for user \"%s\"\n", userName);
    try {
        instance.greeter.authenticate(userName);
        rv = true;
        }
    catch (Error e) {
        error("authentication failed: %s\n", e.message);
        }
    }


  public void reboot() {
    message("reboot clicked\n");
    if (LightDM.get_can_restart()) {
       try {
           LightDM.restart();
           }
       catch (Error e) {
           error("failed to restart(): %s\n", e.message);
           }
       }
    }


  public void powerOff() {
    message("power off clicked\n");
    if (LightDM.get_can_shutdown()) {
       try {
           LightDM.shutdown();
           }
       catch (Error e) {
           error("failed to shutdown: %s\n", e.message);
           }
       }
    }


  public void show_message(string msg, LightDM.MessageType type) {
    message("got message: %s\n", msg);
    instance.widgets.lMsg.set_text(msg);
    }


  public void show_prompt(string text, LightDM.PromptType type) {
    if ("password" in text.down()) {
       try {
           instance.greeter.respond(instance.widgets.ePass.get_text());
           }
       catch (Error e) {
           error("failed to respond to lightdm: %s\n", e.message);
           }
       }
    else {
       message("lightdm requested prompt: \"%s\"\n", text);
       }
    }


  public void authentication_complete() {
    if (instance.greeter.get_is_authenticated()) {
       cache.lastUser = instance.widgets.eUsr.get_text();
       switch (requestedSession) {
         case 0:
              if (cache.session == 1 && instance.config.kSession1 != null) {
                 instance.greeter.start_session(instance.config.kSession1);
                 }
              else if (cache.session == 2 && instance.config.kSession2 != null) {
                 instance.greeter.start_session(instance.config.kSession2);
                 }
              else {
                 message("last session seems not to be available #%d\n", cache.session);
                 if (instance.config.kSession1 != null) {
                    cache.session = 1;
                    cache.flush();
                    instance.greeter.start_session(instance.config.kSession1);
                    }
                 else if (instance.config.kSession2 != null) {
                    cache.session = 2;
                    cache.flush();
                    instance.greeter.start_session(instance.config.kSession2);
                    }
                 }
              break;
         case 1:
              if (instance.config.kSession1 == null) {
                 message("no key for requested session 1!\n");
                 }
              else {
                 cache.session = 1;
                 cache.flush();
                 instance.greeter.start_session(instance.config.kSession1);
                 }
              break;
         case 2:
              if (instance.config.kSession2 == null) {
                 message("no key for requested session 2!\n");
                 }
              else {
                 cache.session = 2;
                 cache.flush();
                 instance.greeter.start_session(instance.config.kSession2);
                 }
              break;
         default:
              message("invalid session requested #%d\n", instance.requestedSession);
              break;
         }
       instance.requestedSession = -1;
       }
    else {
       instance.widgets.lMsg.set_text("login failed!");
       message("login failed for user \"%s\"\n", instance.widgets.eUsr.get_text());
       }
    instance.widgets.eUsr.set_sensitive(true);
    instance.widgets.ePass.set_text("");
    instance.widgets.ePass.set_sensitive(true);
    }
  }


void main(string[] args) {
  Gtk.init(ref args);
  new CinemaGreeter();
  Gtk.main ();
  }
