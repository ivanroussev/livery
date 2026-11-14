#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=0.2.0

for env in prod staging dev sandbox; do
  extra=()
  [ -f "src/superset-$env.css" ] && extra=("src/superset-$env.css")
  {
    printf '/*! livery %s · superset %s · https://github.com/ivanroussev/livery · Apache-2.0 */\n' "$version" "$env"
    cat src/settings.css src/superset.css ${extra[@]+"${extra[@]}"} "src/env/$env.css"
  } > "livery-$env.css"
done
