# TODO

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