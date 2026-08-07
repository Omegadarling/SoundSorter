# SoundSorter on Gameroo

Per-game facts, fixed for the life of the app. The operating manual is
`GAMEROO_NEW_GAME_PUBLISHING_GUIDE.md` (v2) — this file only records what is
specific to SoundSorter.

| Resource | Value |
|---|---|
| slug | `soundsorter` |
| primary hostname | `soundsorter.omegadarling.com` |
| alias hostnames | `soundsort` · `sortsound` · `sortsounds` (all `.omegadarling.com`) |
| host port | `127.0.0.1:3207` |
| image | `soundsorter-server:<release-id>` |
| container / project | `soundsorter-gameroo` |
| network | `soundsorter-gameroo-runtime` |
| host tree | `/srv/soundsorter` |
| edge fragments | `50-soundsorter`, `50-soundsort`, `50-sortsound`, `50-sortsounds` |
| stateful? | no — stateless; everything the app does happens in the browser |

The app is a single static `index.html`, so the image is one digest-pinned
Caddy stage that copies the file in and bakes `/release.json`. There is no
build step and no server code.

## Four hostnames, one backend

The edge helper writes one fragment per `add-game` invocation, so each
hostname is added separately, all pointing at the same upstream — the same
pattern Pitchword uses. The fragment stem is the first argument, which is why
the aliases use their own stems rather than `soundsorter`.

## Publishing an update

```sh
./ops/gameroo/make-release.sh
# then scp the archive and run deploy-game on the host (guide section 6)
```

`make-release.sh` refuses a dirty tree or a HEAD that does not match
`origin/main`, and bumps come from the top-level `VERSION` file. The release
id is `v<VERSION>-<12-char-commit>`.

## Verifying a deploy

`https://<any of the four hostnames>/release.json` must report the release id
you just shipped. The app's footer also shows `v<version>` when served (it is
hidden when the file is opened directly from disk).
