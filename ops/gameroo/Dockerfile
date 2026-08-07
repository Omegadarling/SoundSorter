# syntax=docker/dockerfile:1
#
# SoundSorter is a single static HTML file — no build step, so this is one
# stage: the digest-pinned Caddy runtime that also bakes /release.json.

FROM caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648 AS runtime

ARG RELEASE_VERSION
ARG RELEASE_ID
ARG SOURCE_COMMIT
ARG RUNTIME_MANIFEST_SHA256

LABEL org.opencontainers.image.title="SoundSorter" \
  org.opencontainers.image.description="Local-first audio ordering tool: waveforms, loudness sort, renamed export" \
  org.opencontainers.image.version="${RELEASE_VERSION}" \
  org.opencontainers.image.revision="${SOURCE_COMMIT}" \
  com.gameroo.game="soundsorter" \
  com.gameroo.release="${RELEASE_ID}"

ENV HOME=/tmp \
  XDG_CONFIG_HOME=/tmp/caddy/config \
  XDG_DATA_HOME=/tmp/caddy/data \
  RELEASE_VERSION="${RELEASE_VERSION}" \
  RELEASE_ID="${RELEASE_ID}" \
  SOURCE_COMMIT="${SOURCE_COMMIT}" \
  RUNTIME_MANIFEST_SHA256="${RUNTIME_MANIFEST_SHA256}"

WORKDIR /app

COPY index.html /app/public/index.html
COPY ops/gameroo/Caddyfile /app/Caddyfile
COPY ops/gameroo/healthcheck /app/healthcheck

# Verify the shipped runtime matches what the packager measured, then bake the
# identity file. release.json is written after the manifest check so it is not
# part of the manifest it describes.
RUN test -n "${RELEASE_VERSION}" \
  && test -n "${RELEASE_ID}" \
  && test -n "${SOURCE_COMMIT}" \
  && test -n "${RUNTIME_MANIFEST_SHA256}" \
  && cd /app/public \
  && find . -type f -print \
    | sed 's#^\./##' \
    | LC_ALL=C sort \
    | while IFS= read -r runtime_file; do sha256sum "$runtime_file"; done \
    > /tmp/runtime-manifest.txt \
  && test "$(sha256sum /tmp/runtime-manifest.txt | awk '{print $1}')" = "${RUNTIME_MANIFEST_SHA256}" \
  && printf '%s\n' \
    "{\"game\":\"soundsorter\",\"releaseId\":\"${RELEASE_ID}\",\"version\":\"${RELEASE_VERSION}\",\"sourceCommit\":\"${SOURCE_COMMIT}\",\"runtimeManifestSha256\":\"${RUNTIME_MANIFEST_SHA256}\"}" \
    > /app/public/release.json \
  && chown -R 1000:1000 /app \
  && chmod 0555 /app /app/public /app/healthcheck \
  && chmod 0444 /app/Caddyfile /app/public/index.html /app/public/release.json \
  && setcap -r /usr/bin/caddy \
  && caddy validate --config /app/Caddyfile --adapter caddyfile

USER 1000:1000
EXPOSE 8080

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["run", "--config", "/app/Caddyfile", "--adapter", "caddyfile"]
