
!function(){
	var fs = require('fs'),
		path = require('path'),
		{execSync} = require('child_process'),
		pckjson = require('../../package.json'),
		NPM_VERSION = process.env.npm_package_version,
		ipvPath = path.resolve(__dirname, "../../i-pv/script/", "SNPtoAA.pl"),
		configPath = path.resolve(__dirname, "./", "configOutputTest.json"),
		htmlPath = path.resolve(__dirname, "../../i-pv/circos-p/Output/testOutput/output", "NFKB.html"),
		execute = function (str){
			const retVal = new Promise((res, rej) => {
				execSync(str);
				res(0);
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