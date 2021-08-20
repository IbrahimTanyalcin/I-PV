
!function(){
	var {exec} = require('child_process'),
		pckjson = require('../package.json')
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
	execute('cross-env-shell git tag -f NPM_' + NPM_VERSION)
	.then(function(res){
		return execute('cross-env-shell git tag -f IPV_' + pckjson.org_ipv.version);
	})
	.catch(function(reason){console.log('Promise thrown or rejected. Reason:\n' + reason)});
}();