#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=0.2.0

for env in prod staging dev sandbox; do
  extra=()
  [ -f "src/gitea-$env.css" ] && extra=("src/gitea-$env.css")
  {
    printf '/*! livery %s · gitea %s · https://github.com/ivanroussev/livery · Apache-2.0 */\n' "$version" "$env"
    cat src/settings.css src/gitea.css ${extra[@]+"${extra[@]}"} "src/env/$env.css"
  } > "livery-$env.css"
done
