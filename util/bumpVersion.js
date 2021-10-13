
!function(){
	//process.env.PWD
	//process.cwd()
	var pckjson = require('../package.json'),
		NPM_VERSION = process.env.npm_package_version,
		BUMPTYPE = process.env.BUMPTYPE,
		ipvVersion = pckjson.org_ipv.version,
		fs = require('fs'),
		path = require('path'),
		file = path.resolve(__dirname,'../','package.json');
	if(BUMPTYPE.toLowerCase() === "major"){
		pckjson.org_ipv.version = ipvVersion.toString()
		.replace(/^\s*[0-9]+(?=\.)/gi,function(m,o,s){
			return +m + 1;
		}).replace(/(?<=\.)[0-9]+\s*$/gi,function(m,o,s){
			//return "0".repeat(m.length);
			return 0;
		});
	} else {
		pckjson.org_ipv.version = ipvVersion.toString()
		.replace(/(?<=\.)[0-9]+\s*$/gi,function(m,o,s){
			return +m + 1;
		});
	}
	fs.writeFile(
		file, 
		JSON.stringify(pckjson,null,"  "),
		'utf8',
		function (err) {
			if (err) {
				console.log(err);
			}
		}
	);
}();