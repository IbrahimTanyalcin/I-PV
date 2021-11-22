
const 
	rafx = require('rafx'),
	{getFiles} = require("./getFiles.js"),
	{log} = require("./helpers.js");
	
module.exports = function(){
	return (new Promise((res,rej)=>{
		const 
			watch = function(arg1,argOr,args){log(argOr, ...args);},
			watchThrottle = rafx.throttle(
				watch,
				"IPV daemon is not yet implemented. Run:",
				200
			),
			thenable = rafx
				.async()
				.recurse(function(){
					return watchThrottle(
						"'docker ps', followed by",
						"'docker stop container id' to exit",
						"or 'Ctrl + C' to force quit"
					);
				})
				.while(() => true);
		res({rafx, thenable});
	}))
};