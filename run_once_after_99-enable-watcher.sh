#!/bin/bash

# Reload user daemon to pick up new units
systemctl --user daemon-reload

# 1. Disable and Stop OLD units
systemctl --user disable --now chezmoi-auto-save.path || true

# 2. Enable and Start NEW units
systemctl --user enable --now chezmoi-watch-packages.path
systemctl --user enable --now chezmoi-watch-services.path
