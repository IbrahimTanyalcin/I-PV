
!async function(){
	const 
		ARGV = process.argv.slice(2),
		{execute} = require("./js/execute.js"),
		{osExecute} = require("./js/osExecute.js"),
		{select, signalReceiver, catcher, log} = require("./js/helpers.js"),
		{getInfo} = require("./js/getInfo.js"),
		info = await getInfo(process.env, ARGV);
	
	select(process)
	.on("exit", (code) => {
		console.log(`Exiting with code: ${code}`);
	})
	.on("SIGINT", signalReceiver)
	.on("SIGTERM", signalReceiver);
	
	if(info instanceof Error){
		console.log("Unable to parse parameters.");
		catcher(info);
	}
	console.log("Keeping the container up...");
	/*
	#You would think a spawn would be more
	#appropriate here, however it does not
	#prevent the container from exiting
	const child = spawn("/bin/bash",
		[
			"-c",
			"tail -f /dev/null"
		],
		{
			cwd: "/app",
			stdio: "ignore",
			detached: true,
			shell: "/bin/bash",
			windowsHide: true
		}
	);
	child.on("error", (err) => {
		console.log(err, err.message);
	});
	child.unref();
	*/
	osExecute("/bin/bash -c tail -f /dev/null",{exclude:"^win"})
	.catch(catcher);
	
	log(
		"Here are your parameters:",
		JSON.stringify(info,null,"\t")
	);
	
	const 
		getNodeBinaries = require("./js/getNodeBinaries"),
		getDockerBinaries = require("./js/getDockerBinaries"),
		{getFiles} = require("./js/getFiles.js");
	
	getFiles(info.nodeBinaries, {depth:1})
	.then(files => getNodeBinaries(...files))
	.then(nodeBinaries => {
		return getFiles(info.dockerBinaries, {depth:1})
		.then(files => {
			return getDockerBinaries(...files)
			.then(dockerBinaries => {
				return {...dockerBinaries, ...nodeBinaries};
			});
		});
	}).then(binaries => {
		try {
			
			log(
				"Binaries are", 
				JSON.stringify(binaries,null,"\t")
			);
			
			if(info.nodaemon){
				execute(
					
					binaries["cross-env-shell"]
					+ " perl "
					+ info.ipvPath 
					+ " --config " 
					+ info.input
					
					/*binaries["cross-env-shell"] + " perl ./test.pl"*/
				).then(function(){
					console.log("Execution success.");
					process.exit(0);
				}).catch(catcher);
			} else {
				const daemon = require("./js/daemon.js");
				daemon()
				.then(({rafx, thenable}) => 
					rafx.async()
					.skipFrames(300)
					.then(()=> {
						//console.log("5 seconds elapsed, aborting..");
						//thenable.break();
					})
				)
				.catch(catcher);
			}
		} catch (err) {
			catcher(err);
		}
	})
	.catch(catcher);
}();
