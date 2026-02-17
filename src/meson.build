gtk4 = dependency('gtk4')
layershell = dependency('gtk4-layer-shell-0')
gio = dependency('gio-2.0')
gio_unix = dependency('gio-unix-2.0')
json = dependency('json-glib-1.0')
nm = dependency('libnm')
m = meson.get_compiler('c').find_library('m')

gnome = import('gnome')
sass = find_program('sass', required: true)

#
# Step 1: Compile SCSS → CSS
#
style_css = custom_target(
  'style-css',
  input: '../assets/style.scss',
  output: 'style.css',
  command: [
    sass,
    '@INPUT@',
    '@OUTPUT@'
  ],
  build_by_default: true
)

#
# Step 2: Compile GResource (embeds CSS + SVG into binary)
#
resources = gnome.compile_resources(
  'topbar-resources',
  '../assets/topbar.gresource.xml',
  source_dir: '../assets',
  dependencies: style_css,
  c_name: 'topbar'
)

#
# Step 3: Build executable
#
executable(
  'topbar',

  sources: [
    'main.vala',
    'app.vala',

    'ui/bar.vala',
    'ui/bar_left.vala',
    'ui/bar_center.vala',
    'ui/bar_right.vala',
    'ui/niri_workspaces.vala',
    'ui/system_resources.vala',
    'ui/tray.vala',

    'services/utils.vala',
    'services/niri_ipc.vala',
    'services/system_resources.vala',
    'services/screen_rec.vala',
    'services/battery.vala',
    'services/network.vala',
    'services/volume.vala',
    'services/bluetooth.vala',
    'services/tray.vala',

    resources
  ],

  dependencies: [
    gtk4,
    layershell,
    gio,
    gio_unix,
    json,
    nm,
    m
  ],

  install: true
)
