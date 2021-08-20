!function(){
	const {exec} = require('child_process'),
		ARGV = process.argv.slice(2),
		ARG = ARGV[0], //commandline arg 1
		ARGmessage = ARGV[1] || "", //commandline arg 2
		branchName = process.env.BRANCH_NAME,
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

	execute('cross-env-shell git checkout ' + branchName)
	.then(function(res){
		return execute('cross-env-shell git merge -s ours master')
	})
	.then(function(res){
		return execute('cross-env-shell git checkout master');
	})
	.then(function(res){
		return execute('cross-env-shell git merge ' + branchName);
	})
	.catch(function(reason){console.log('Promise thrown or rejected. Reason:\n' + reason)});
}();
