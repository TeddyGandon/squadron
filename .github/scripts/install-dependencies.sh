#!/usr/bin/env bash
# Installs npm dependencies for the project in the current directory, if it has any.
set -euo pipefail

if [[ -f package-lock.json || -f npm-shrinkwrap.json ]]; then
  npm ci
elif [[ -f package.json ]]; then
  npm install
else
  echo 'No package.json found; the test command must provide its own setup.'
fi
