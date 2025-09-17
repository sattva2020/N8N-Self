#!/usr/bin/env bash
# List tracked files larger than 5MB
git ls-files -z | xargs -0 du -b 2>/dev/null | awk '$1 > 5242880 { printf("%s bytes: %s\n", $1, $2) }' || true
