
!function(){
	/*before running this
		- create a new repo at another site
		- get the new repo's remote addr: https://new-mirror-repo
		- git clone --mirror https://repo-to-mirror.git
		- cd to the cloned folder
		- git remote set-url --push origin https://new-mirror-repo
	*/
	var {exec} = require('child_process'),
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
	execute('git fetch -p origin')
	.then(function(res){
		return execute('git push --mirror');
	})
	.catch(function(reason){console.log('Promise thrown or rejected. Reason:\n' + reason)});
}();