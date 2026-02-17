#!/bin/bash

set -e

echo "Compiling SCSS..."
sass assets/style.scss assets/style.css

echo "Compiling resources..."
glib-compile-resources \
  --generate-source \
  --target=src/topbar-resources.c \
  --sourcedir=assets \
  assets/topbar.gresource.xml

echo "Compiling Vala..."

valac \
  --pkg gtk4 \
  --pkg gtk4-layer-shell-0 \
  --pkg gio-2.0 \
  --pkg gio-unix-2.0 \
  --pkg json-glib-1.0 \
  --pkg libnm \
  -X -lm \
  src/*.vala \
  src/services/*.vala \
  src/ui/*.vala \
  src/topbar-resources.c \
  -o topbar

echo "Done."

./topbar
