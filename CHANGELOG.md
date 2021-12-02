# CHANGELOG

## NPM_0.1.8 - NPM_0.1.10
- Various bug fixes
- Added $(BRANCH_NAME) variable to azure.yaml
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