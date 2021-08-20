
!function(){
	var pckjson = require('../package.json'),
		NPM_VERSION = process.env.npm_package_version,
		BUMPTYPE = process.env.BUMPTYPE,
		ipvVersion = pckjson.org_ipv.version,
		fs = require('fs'),
		path = require('path'),
		file = path.join("../", "package.json");
	if(BUMPTYPE.toLowerCase() === "major"){
		pckjson.org_ipv.version = ipvVersion.toString()
		.replace(/^\s*[0-9]+(?=\.)/gi,function(m,o,s){
			return +m + 1;
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