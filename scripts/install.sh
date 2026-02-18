#!/bin/bash

rm -rf build/
meson setup build
meson compile -C build
sudo meson install -C build
