
!function(){
	/*before running this
		- create a new repo at another site
		- get the new repo's remote addr: https://new-mirror-repo
		- git clone --mirror https://repo-to-mirror.git
		- cd to the cloned folder
		- git remote set-url --push origin https://new-mirror-repo
	*/
	var fs = require('fs'),
		path = require('path'),
		{exec} = require('child_process'),
		NPM_VERSION = process.env.npm_package_version,
		execute = function (str){
			const retVal = new Promise((res, rej) => {
				exec(str, (err, stdout, stderr) => {
					console.log(str, "\n");
					if (err) {
						rej(`error: ${err.message}`);
						return;
					}
					if (stderr) {
						if(stderr.match(/^\s*warning/i)){ //suppress these ->: warning: LF will be replaced by CRLF in package.json
							console.log("encountered a warning:", "\n", stderr, "\n");
							res(0);
							return;
						} else if (stderr.match("To https:\/\/")) { //changes pushed to repo, don't know why it goes to stderr
							console.log('pushed to repo successfully\n');
							res(0);
							return;
						} else if(!err || !err.code){
							//Git writes all non-err warnings
							//to stderr for whatever reason
							//https://stackoverflow.com/questions/57016157/stop-git-from-writing-non-errors-to-stderr
							res(
								`git issued stderr but exited with 0:
								${stderr}`
							);
							return;
						}
						rej(`stderr: ${stderr}`);
						return;
					}
					if (err === null){
						res(0)
						return;
					}
					rej("unknown reason for rejection");
					return;
				});
			});
			return retVal;
		},
		findDir = function(
			start,
			search,
			opts
		) {
			opts = opts || {
				fsConstants: fs.constants.F_OK | fs.constants.R_OK,
				depth: 1
			};
			return new Promise((res, rej) => {
				for (var i = 0, j = start; i < opts.depth; ++i){
					fs.access(
						path.join(j, search),
						opts.fsConstants,
						((i,j) => (err) => {
								if(!err){
									res(j);
								} else if (i === opts.depth - 1 ) {
									rej(opts.err || err);
								}
							}
						)(i,j)
					);
					j = path.join(j, "..");
				}
			});
		};
	findDir(__dirname, "/node_modules", {depth: 5})
	.then(rootFolder => {
		try {
			var mirrorConfig = require(path.join(rootFolder, "/mirror.conf.json"));
		} catch (err) {
			throw err;
		}
		return {rootFolder, mirrorConfig};
	})
	.then(({rootFolder, mirrorConfig}) => {
		return findDir(rootFolder, mirrorConfig.path, {depth: 5})
		.then(folder => path.join(folder, mirrorConfig.path));
	})
	.then(mirrorFolder => {
		process.chdir(mirrorFolder);
		return execute('git fetch -p origin');
	})
	.then(function(res){
		return execute('git push --mirror');
	})
	.catch(err => {
		if (err instanceof Error) {
			console.log(err.message);
		} else {
			console.log(err);
		}
	});
	/*.catch(function(reason){console.log('Promise thrown or rejected. Reason:\n' + reason)});*/
}();