
!function(){
	var fs = require('fs'),
		path = require('path'),
		{exec} = require('child_process'),
		pckjson = require('../../package.json'),
		NPM_VERSION = process.env.npm_package_version,
		ipvPath = path.resolve(__dirname, "../../i-pv/script/", "SNPtoAA.pl"),
		configPath = path.resolve(__dirname, "./", "configOutputTest.json"),
		htmlPath = path.resolve(__dirname, "../../i-pv/circos-p/Output/testOutput/output", "NFKB.html"),
		execute = function (str){
			const retVal = new Promise((res, rej) => {
				const childProcess = exec(str, (err, stdout, stderr) => {
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
				childProcess.stdout.pipe(process.stdout);
			});
			return retVal;
		};
	execute('cross-env-shell perl ' + ipvPath + " --config " + configPath)
	.then(function(res){
		fs.access(htmlPath, fs.constants.F_OK | fs.constants.R_OK, (err) => {
			if(!err){
				console.log("Execution of " + __filename + " completed successfully.\n");
				return;
			}
			console.log(
				htmlPath 
				+ " could not be created. Execution of " 
				+ __filename
				+ " failed.\n"
			);
			process.exitCode = 1;
		});
	})
	.catch(function(reason){
		console.log('Promise thrown or rejected. Reason:\n' + reason);
		process.exitCode = 1;
	});
}();