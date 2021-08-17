!function(){
	const {exec} = require('child_process'),
		ARGV = process.argv.slice(2),
		ARG = ARGV[0],
		ARGmessage = ARGV[1] || "",
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
		};
	if(!/^(?:[0-9]+\.){2}[0-9]+$/.test(ARG)){
		console.log("child processes use '${npm_package_version}' or 'process.env.npm_package_version', "
		+ "make sure version argument is semver compliant, like 3.2.1 etc.");
		return;
	}
	execute('npm run updatePckgJSON -- ' + ARG)
	.then(function(res){
		return execute('npm run updateReadme -- ' + ARG)
	})
	.then(function(res){
		return execute('npm run gitAddAll');
	})
	.then(function(res){
		return execute("cross-env-shell git commit -m " + ['\\"',ARG, ARGmessage,'\\"'].join(" "));
	})
	.then(function(res){
		return execute("cross-env-shell git tag -f " + ARG);
	})
	.then(function(res){
		return execute("npm run gitPush && npm run gitPushTags");
	})
	.catch(function(reason){console.log("Promise thrown or rejected. Reason:\n" + reason)});
}();
