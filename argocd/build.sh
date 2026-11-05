#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=0.1.1

for env in prod staging dev sandbox; do
  extra=()
  [ -f "src/argocd-$env.css" ] && extra=("src/argocd-$env.css")
  {
    printf '/*! livery %s · argocd %s · https://github.com/ivanroussev/livery · Apache-2.0 */\n' "$version" "$env"
    cat src/settings.css src/argocd.css ${extra[@]+"${extra[@]}"} "src/env/$env.css"
  } > "livery-$env.css"
done
