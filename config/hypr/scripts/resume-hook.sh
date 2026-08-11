#!/bin/bash

dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member=PrepareForSleep" | while read -r line; do
    case "$line" in
        *"boolean false"*)
            sleep 2
            hyprctl dispatch dpms on
            ;;
    esac
done
