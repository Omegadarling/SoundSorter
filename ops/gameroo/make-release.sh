#!/bin/sh
# Packages a SoundSorter release for the Gameroo deployer.
# Contract: guide section 6 (clean tree, HEAD == origin/main, immutable
# release id, manifest appended INSIDE the archive, checksums after append).
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$PROJECT_ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "Refusing to package a dirty source tree." >&2
  exit 1
fi

SOURCE_COMMIT=$(git rev-parse HEAD)
ORIGIN_COMMIT=$(
  git ls-remote --exit-code origin refs/heads/main | awk 'NR == 1 {print $1}'
)
if [ "$SOURCE_COMMIT" != "$ORIGIN_COMMIT" ]; then
  echo "Refusing: local HEAD does not match origin/main." >&2
  exit 1
fi

RELEASE_VERSION=$(tr -d ' \t\r\n' < VERSION)
if [ -z "$RELEASE_VERSION" ]; then
  echo "Unable to read VERSION." >&2
  exit 1
fi

SHORT_COMMIT=$(printf '%s' "$SOURCE_COMMIT" | cut -c1-12)
RELEASE_ID="v${RELEASE_VERSION}-${SHORT_COMMIT}"
case "$RELEASE_ID" in
  ''|.|..|[!A-Za-z0-9]*|*[!A-Za-z0-9_.-]*)
    echo "Invalid release ID: $RELEASE_ID" >&2
    exit 1
    ;;
esac
if [ "${#RELEASE_ID}" -gt 63 ]; then
  echo "Release ID is longer than the deployer's 64-character limit." >&2
  exit 1
fi

OUTPUT_ROOT="${1:-$PROJECT_ROOT/dist/gameroo}"
OUTPUT_DIR="$OUTPUT_ROOT/$RELEASE_ID"

if [ -e "$OUTPUT_DIR" ]; then
  echo "Refusing to overwrite existing release output: $OUTPUT_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="${RELEASE_ID}-source.tar"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"

git archive --format=tar --prefix="${RELEASE_ID}/" \
  "$SOURCE_COMMIT" > "$ARCHIVE_PATH"

BASE_IMAGE="caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648"

# The runtime is exactly what lands in /app/public before release.json is
# baked — one file. Paths and format must match the Dockerfile's check.
RUNTIME_LIST="$OUTPUT_DIR/runtime-manifest.txt"
{
  printf '%s\n' index.html
} | LC_ALL=C sort | while IFS= read -r runtime_file
do
  test -f "$runtime_file"
  git ls-files --error-unmatch "$runtime_file" >/dev/null
  shasum -a 256 "$runtime_file"
done > "$RUNTIME_LIST"

RUNTIME_FILE_COUNT=$(wc -l < "$RUNTIME_LIST" | tr -d ' ')
RUNTIME_BYTES=0
while IFS= read -r manifest_line
do
  runtime_file=${manifest_line#*  }
  if runtime_size=$(stat -f '%z' "$runtime_file" 2>/dev/null); then
    :
  else
    runtime_size=$(stat -c '%s' "$runtime_file")
  fi
  RUNTIME_BYTES=$((RUNTIME_BYTES + runtime_size))
done < "$RUNTIME_LIST"
RUNTIME_MANIFEST_SHA256=$(
  shasum -a 256 "$RUNTIME_LIST" | awk '{print $1}'
)

# Travels inside the archive; the deployer passes each KEY=value as a
# docker --build-arg. GAME_HOST_ALIASES is documentation for the human adding
# edge routes — the deployer ignores it.
cat > "$OUTPUT_DIR/release-manifest.env" <<EOF
GAME_SLUG=soundsorter
GAME_HOST=soundsorter.omegadarling.com
GAME_HOST_ALIASES=soundsort.omegadarling.com,sortsound.omegadarling.com,sortsounds.omegadarling.com
GAME_CONTAINER_PORT=8080
GAME_PROJECT=soundsorter-gameroo
GAME_CONTAINER=soundsorter-gameroo
GAME_NETWORK=soundsorter-gameroo-runtime
GAME_ROOT=/srv/soundsorter
GAME_IMAGE=soundsorter-server:${RELEASE_ID}
EDGE_FRAGMENT=50-soundsorter
RELEASE_VERSION=${RELEASE_VERSION}
RELEASE_ID=${RELEASE_ID}
SOURCE_COMMIT=${SOURCE_COMMIT}
BASE_IMAGE=${BASE_IMAGE}
RUNTIME_FILE_COUNT=${RUNTIME_FILE_COUNT}
RUNTIME_BYTES=${RUNTIME_BYTES}
RUNTIME_MANIFEST_SHA256=${RUNTIME_MANIFEST_SHA256}
EOF

# Append the manifest into the archive under the release prefix, where the
# deployer expects it (staged path instead of GNU-only --transform).
mkdir -p "$OUTPUT_DIR/$RELEASE_ID"
cp "$OUTPUT_DIR/release-manifest.env" "$OUTPUT_DIR/$RELEASE_ID/release-manifest.env"
tar -rf "$ARCHIVE_PATH" -C "$OUTPUT_DIR" "$RELEASE_ID/release-manifest.env"
rm -r "$OUTPUT_DIR/$RELEASE_ID"

ARCHIVE_BYTES=$(wc -c < "$ARCHIVE_PATH" | tr -d ' ')
ARCHIVE_SHA256=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')

(
  cd "$OUTPUT_DIR"
  shasum -a 256 \
    "$ARCHIVE_NAME" \
    runtime-manifest.txt \
    release-manifest.env
) > "$OUTPUT_DIR/SHA256SUMS"

printf 'release:  %s\n' "$RELEASE_ID" >&2
printf 'archive:  %s (%s bytes)\n' "$ARCHIVE_SHA256" "$ARCHIVE_BYTES" >&2
printf '%s\n' "$OUTPUT_DIR"
