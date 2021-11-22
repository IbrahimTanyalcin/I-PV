
const 
	{findDir} = require("./findDir.js"),
	path = require("path"),
	{getArgs} = require("./getArgs.js");
exports.getInfo = async function(ENV, ARGS){
	let cache = require?.main?._ipvCache?.getInfo;
	if(cache){
		return cache;
	}
	let result;
	try {
		ARGS = getArgs(ARGS);
		const 
			inputFileName = ARGS.input || "config.json",
			mountPath = ARGS.mount || ENV.MOUNT_PATH || "/app/mount",
			rootFolder = await findDir(__dirname, "/node_modules", {depth: 5}).catch(err => err);
		if (rootFolder instanceof Error){
			throw new Error("Unable to locate /node_modules folder.");
		}
		result = {
			version: ENV.npm_package_version,
			rootFolder: rootFolder,
			nodeBinaries: path.resolve(rootFolder, "node_modules/.bin/"),
			dockerBinaries: path.resolve(rootFolder, "bin"),
			ipvPath: path.resolve(rootFolder, "node_modules/ibowankenobi-i-pv/i-pv/script/", "SNPtoAA.pl"),
			nodaemon: ARGS.nodaemon,
			input: path.resolve(mountPath, inputFileName)
		};
		require.main._ipvCache = {getInfo: result};
	} catch (err) {
		result = err;
	} finally {
		return result;
	}
};