#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SITE_DIR="$SCRIPT_DIR/whoami"
readonly DEPLOY_BRANCH="${DEPLOY_BRANCH:-gh-page}"
readonly SITE_URL="${SITE_URL:-https://kurrrioo.github.io/}"
readonly COMMIT_MESSAGE="${DEPLOY_MESSAGE:-Deploy: Update site content}"

BUILD_DIR=""
DEPLOY_DIR=""

die() {
  printf 'Fehler: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$DEPLOY_DIR" && -d "$DEPLOY_DIR" ]]; then
    git -C "$SCRIPT_DIR" worktree remove --force "$DEPLOY_DIR" >/dev/null 2>&1 || true
  fi
  if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
    rm -rf -- "$BUILD_DIR"
  fi
}

trap cleanup EXIT

command -v git >/dev/null 2>&1 || die "git wurde nicht gefunden."
command -v hugo >/dev/null 2>&1 || die "hugo wurde nicht gefunden."
git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1 ||
  die "Das Script muss innerhalb eines Git-Repositories liegen."
[[ -f "$SITE_DIR/hugo.toml" ]] || die "Hugo-Konfiguration fehlt: $SITE_DIR/hugo.toml"
git -C "$SCRIPT_DIR" remote get-url origin >/dev/null 2>&1 ||
  die "Das Remote 'origin' ist nicht konfiguriert."

printf 'Aktualisiere Referenz für origin/%s ...\n' "$DEPLOY_BRANCH"
git -C "$SCRIPT_DIR" fetch --quiet origin "$DEPLOY_BRANCH" ||
  die "Der Branch origin/$DEPLOY_BRANCH konnte nicht geladen werden."

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hugo-build.XXXXXX")"
DEPLOY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hugo-deploy.XXXXXX")"
rm -rf -- "$DEPLOY_DIR"

printf 'Erzeuge Hugo-Build für %s ...\n' "$SITE_URL"
hugo \
  --source "$SITE_DIR" \
  --destination "$BUILD_DIR" \
  --baseURL "$SITE_URL" \
  --minify

[[ -f "$BUILD_DIR/index.html" ]] || die "Der Hugo-Build enthält keine index.html."

printf 'Bereite Deployment-Worktree vor ...\n'
git -C "$SCRIPT_DIR" worktree add --detach --quiet "$DEPLOY_DIR" "origin/$DEPLOY_BRANCH"
find "$DEPLOY_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf -- {} +
cp -a "$BUILD_DIR"/. "$DEPLOY_DIR"/
touch "$DEPLOY_DIR/.nojekyll"

git -C "$DEPLOY_DIR" add --all
if git -C "$DEPLOY_DIR" diff --cached --quiet; then
  printf 'Keine Änderungen zu veröffentlichen.\n'
  exit 0
fi

git -C "$DEPLOY_DIR" \
  -c user.name="${GIT_AUTHOR_NAME:-GitHub Actions}" \
  -c user.email="${GIT_AUTHOR_EMAIL:-github-actions[bot]@users.noreply.github.com}" \
  commit --quiet -m "$COMMIT_MESSAGE"

printf 'Veröffentliche auf origin/%s ...\n' "$DEPLOY_BRANCH"
git -C "$DEPLOY_DIR" push --quiet origin "HEAD:$DEPLOY_BRANCH"
printf 'Deployment erfolgreich.\n'
