
/*
	executes a given string, if the os string
	returned by os.platform() matches include 
	regexp and NOT matches exclude regexp
*/
const 
	{execute} = require('./execute.js'),
	{log} = require('./helpers.js'),
	os = require("os")
	osExecute = function (
		str,
		{
			include:incRgx = {test:() => true}, 
			exclude:exRgx = {test:() => false},
			includeFlags:incFlags = "gi",
			excludeFlags:exFlags = "gi"
		} = {}
	){
		const platform = os.platform();
		if(Object(incRgx) instanceof String){
			incRgx = new RegExp(incRgx, incFlags);
		}
		if(Object(exRgx) instanceof String){
			exRgx = new RegExp(exRgx, exFlags);
		}
		if(incRgx.test(platform) && !exRgx.test(platform)){
			return execute(str);
		}
		return Promise.resolve(log(
			"Execution of:",
			str,
			"discarded due to OS platform. Your OS:",
			platform,
			"Include criteria:",
			incRgx instanceof RegExp ? incRgx : incRgx.test,
			"Exclude criteria:",
			exRgx instanceof RegExp ? exRgx : exRgx.test
		));
	};

exports.osExecute = osExecute;