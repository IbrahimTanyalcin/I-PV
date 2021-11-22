
/*
	gets the full path string to a binary with fName
	ex: getDockerBinaries("cross-env-shell")
*/
const 
	{getInfo} = require('./getInfo.js'),
	path = require("path");
module.exports = async function(...args){
	const info = await getInfo();
	return Object.assign(
		{},
		...args.map(d => {
			return {[d]: path.resolve(info.dockerBinaries, d)};
		})
	);
};