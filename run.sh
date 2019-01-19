#!/bin/bash

set -e
set -o pipefail
set -u

swift build
./.build/debug/SpotifyMatch "$1" "$2"
