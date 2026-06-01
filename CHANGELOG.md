# CHANGELOG

## NPM_0.1.30 / IPV_2.6
- **Security hardening**: Removed all references to untrusted external domain (`danml.com`) from templates and example outputs.
- Inlined `download.js` (v4.21) into generated HTML via Perl script (`SNPtoAA.pl`) using a template placeholder (`<!-- IPV_INLINE_DOWNLOAD_JS -->`), eliminating the need to load it from an external domain at runtime.
- Added `Content-Security-Policy` meta tag to the HTML template restricting script sources to `'self'`, `'unsafe-inline'`, `'unsafe-eval'`, `https://d3js.org`, and `https://nytimes.github.io`.
- Added `integrity` and `crossorigin` attributes to the d3.v3.min.js and svg-crowbar script tags for subresource integrity (SRI) verification.
- Bundled a local copy of `d3.v3.min.js` under `circos-p/templates/` for offline/inlining use.
- Sanitized all 7 existing example outputs (HTML + TXT) in `circos-p/Output/`.
- Modernized Dockerfile from `node:16` to `node:24`.
- Bumped Docker label version to `1.0.13`, docker app package to `1.0.15`.
- Added `ci.yml` GitHub Actions workflow for automated build and static checks.

## NPM_0.1.27 - NPM_0.1.29
- Added an extra check at the `.github/workflows/sync-public.yml` to check if public exists to prevent the workflow from erring. To use the workflow replace `'your-user-name/your-repo'` with the correct values from your fork. This should synchronize your public branch with I-PV's master once a day.

## NPM_0.1.24 - NPM_0.1.26
- Added `sync-public.yml` which is a `azure.yaml` equivalent of syncing public branch of your fork. Keep this workflow in your master
if you want the scheduled cron jobs to take effect
- Converted `http://` resources to protocol relative URIs in `i-pv/circos-p/templates/javascript.txt`

## NPM_0.1.19 - NPM_0.1.23 / IPV_2.5

- Below fields are now optional:
  - `variation.fileName`
  - `variation.skipHeader`
  - `variation.separator`
  - `variation.colSubsType`
  - `variation.colValStat`
  - `variation.colGeneStrand`
  - `variation.transcriptID`
  - `variation.colPolyphen2`
  - `variation.colSift2`
  - `variation.maf`
- Added `circos.cleanup` parameter that only leaves the `*.html` as output and removes rest of the complementary files.
- Added `circos.perms` that sets the permissions on the output files
- Added `datatracks.perms` that sets the permissions on the output files.

## NPM_0.1.12 - NPM_0.1.18
- Added $(BRANCH_NAME) variable to azure.yaml
- Modified `docker/js/getFiles.js` to include node directory entry objects (`dirent`) that either pass `dirent.isFile()` or `dirent.isSymbolicLink()` to correctly list available binaries.

## NPM_0.1.8 - NPM_0.1.11
- Various bug fixes
- ~~Added $(BRANCH_NAME) variable to azure.yaml~~
- Binaries are logged on when docker is started

## NPM_0.1.6 - NPM_0.1.7
- Changed `syncMirror` to update tags.

## NPM_0.1.5
- Changed `syncMirror` to ignore `stderr` when process exits with 0. ([See](https://stackoverflow.com/questions/57016157/stop-git-from-writing-non-errors-to-stderr))

## NPM_0.1.4 / IPV_2.4
- Updated mirroring function `syncMirror`.
- Added `azure.yaml`.

## NPM_0.1.3 / IPV_2.3
- Updates to readme and documentation of config options.
- Minor bug fixes.

## NPM_0.1.2 / IPV_2.2
- Update `.gitattributes` to prevent auto EOL conversion for files under `templates/`

## NPM_0.1.1 / IPV_2.1
- Automatically transliterates backslashes to forward slashes in the `config.json`.
- Prohibits use of [`\ / . ? * ¥`](https://docs.microsoft.com/en-us/windows/win32/intl/character-sets-used-in-file-names) characters in `name` field of `config.json` and generated file names.
- EOL conversion to Unix for files under `templates/` 
- Bug fixes for Linux cross-compatibility

## NPM_0.1.0 / IPV_2.0
- Added a JSON configuration option `--config xyz.json` that allows the user to generate images, bypassing manual provision of arguments. Especially usefull if you want to generate multiple figures on the fly and do not want to manually type in yes/no questions through `STDIN`
- No need to modify `my $circos` path inside `SNPtoAA.pl`, automatically uses the `circos.pm` inside the repo folder.
- Removed 2 copies of circos folder, now the there is only a single folder and it does not trigger the unescaped left brace warning.
- Bug fixes

## NPM_0.0.3 / IPV_1.47
- Updated version string in `SNPtoAA.pl`
- Version number is removed from `package.json`'s main entry point. Regarless of versions, entry point will be same (`SNPtoAA.pl`).
- Removed extra copies of ACE2 and Sars-Cov-2 spike examples
- Added `FindBin` module from `relativePathPropositon` branch to remedy potential issues with relative paths in different OSs