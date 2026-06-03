# TODO

## 20260603
- Phase out remaining `cross-env` / `cross-env-shell` usages. Background: `cross-env-shell` internally calls `spawn(cmd, args, {shell: true})` (see `cross-env/src/index.js`), which triggers Node 24+ `[DEP0190] DeprecationWarning` and will become a hard error in a future Node release. The 5 critical occurrences in the CI path have already been removed (root `package.json` test script, `util/test/outputTest.js`, `docker/app/main.js`, `docker/app/package.json` test script + dependency). The remaining occurrences (release tooling — `bumpPatchNPM/MinorNPM/MajorNPM`, `bumpPatchIPV/MinorIPV/MajorIPV`, `gitCommit`, `gitTag`, `syncMirror`, `replaceMasterBranch` in root `package.json`, plus `util/gitTag.js`, `util/replaceMasterBranch.js`, `util/test/outputTestSync.js`) still emit DEP0190 but do not break anything because they are run only on developer machines and their stderr is not parsed catastrophically. Since the project is Linux-only in practice (Docker = Linux, GHA = Linux), `cross-env` is unnecessary. Migration notes:
  - Scripts with no env setter (`gitCommit`, `gitTag`, `syncMirror`, `bumpPatchNPM`, etc.): drop the `cross-env-shell` prefix entirely.
  - Scripts with env setters (`bumpPatchIPV: cross-env-shell BUMPTYPE=patch node ...`, `replaceMasterBranch: cross-env-shell BRANCH_NAME=v1.46 node ...`): use the native POSIX `KEY=value command` syntax, e.g. `BUMPTYPE=patch node ./util/bumpVersion.js`.
  - After migration, remove `cross-env` from `devDependencies` in root `package.json`.
- Once cross-env is fully removed, update `i-pv/ReadMe.md` to drop the `^7.0.3 cross-env` line under "I-PV NodeJS dev dependencies".

## 20211210

- Insert `make_path` errors (if permission denied) before the fatal errors thrown in `config.pm`
- Find if there is a way to turn on autoflush on `IPC::System` when invoking circos
- Warn users when they invoke the docker container without using `--mount` option by checking if `/app/mount` exists.
- Complete daemon functionality of the docker image
- Add verbose option to docker image to hide logs when not requested
- Add hit testing mechanism to elements to reduce event handlers (prerequisite: Reduce dependencies)

## 20211102
- Reduce dependencies (except SVG crowbar)
- Add config option to customize HTML meta fields
- ~~Allow variation file to be optional~~ ✓
- ~~Allow certain variation config options to auto fallback to `base change` column~~ ✓