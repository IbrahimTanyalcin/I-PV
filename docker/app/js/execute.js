
/*
	executes a given string, filters out
	git related warnings and output that
	is auto written to stderr, returns
	a Promise
*/
const 
	{exec, spawn} = require('child_process'),
	{log} = require('./helpers.js'),
	execute = function (str){
		log("Executing:",str);
		const retVal = new Promise((res, rej) => {
			const childProcess = exec(str, (err, stdout, stderr) => {
				//console.log(str, "\n"); - I think It is better to log it rightaway rather than callback
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
			childProcess.stdout.pipe(process.stdout);
		});
		return retVal;
	};

exports.execute = execute;