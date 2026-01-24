project(
  'topbar',
  'vala',
  version: '0.1'
)

gtk4 = dependency('gtk4')
layershell = dependency('gtk4-layer-shell-0')
gio = dependency('gio-2.0')
gio_unix = dependency('gio-unix-2.0')
json = dependency('json-glib-1.0')

executable(
  'topbar',
  sources: [
    'main.vala',
    'app.vala',
    'bar.vala',
    'bar_left.vala',
    'bar_center.vala',
    'bar_right.vala',
    'services/niri_events.vala',
  ],
  dependencies: [gtk4, layershell, gio, gio_unix, json],
)
