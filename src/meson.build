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
    'ui/bar.vala',
    'ui/bar_left.vala',
    'ui/bar_center.vala',
    'ui/bar_right.vala',
    'ui/niri_workspaces.vala',
    'ui/system_resources.vala',
    'services/utils.vala',
    'services/niri_ipc.vala',
    'services/system_resources.vala',
    'services/screen_rec.vala',
  ],
  dependencies: [gtk4, layershell, gio, gio_unix, json],
)
