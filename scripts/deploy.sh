#!/usr/bin/env bash
# Called by .github/workflows/deploy.yml with the target environment:
#   development | staging | production
# Replace the body with the project's deployment. Use environment secrets
# (Settings → Environments → <env> → secrets), exposed to the workflow via `env:`.
set -euo pipefail

TARGET_ENV="${1:?usage: scripts/deploy.sh <development|staging|production>}"
echo "Deploying $(git rev-parse --short HEAD) to $TARGET_ENV"

# ---- Project-specific deployment goes here ---------------------------------
# docker build -t ghcr.io/<org>/<app>:$GITHUB_SHA . && docker push ...
# kubectl apply -k deploy/$TARGET_ENV
# npx vercel deploy --prod   (production only)

echo "Deploy placeholder finished for $TARGET_ENV"
