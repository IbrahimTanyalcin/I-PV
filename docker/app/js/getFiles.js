

const fs = require('fs'),
	path = require('path');

/*
Reads all files based on depth, starting from 1
which means './'. Do not pass explicit args 
other than dir and opts. See below for usage*/	
function getFiles(
	dir = "./", 
	opts = {depth: 3, relativeTo: "./"}, 
	result = [], 
	callsRemaining = {value:1},
	resolver,
	rejector
){
	let 
		depth = opts?.depth ?? 3,
		relativeTo = opts?.relativeTo ?? "./";
	if(!depth){
		return Promise.resolve(result);
	}
	depth--;
	if(resolver === undefined) {
		relativeTo = path.resolve(dir, relativeTo);
		return new Promise((res,rej) => {
			process(dir, depth, relativeTo, result, callsRemaining, res, rej);
		});
	} else {
		process(dir, depth, relativeTo, result, callsRemaining, resolver, rejector);
	}
}

function process(dir, depth, relativeTo, result, callsRemaining, resolver, rejector){
	fs.readdir(dir, {withFileTypes: true},(err,files) => {
		if(err){
			// If the directory doesn't exist, resolve with whatever we have so far
			// (empty array for a top-level call). This handles the case where
			// node_modules/.bin is absent because no package installs binaries.
			if(err.code === 'ENOENT'){
				callsRemaining.value--;
				if(!callsRemaining.value){
					resolver(result);
				}
				return;
			}
			rejector(err);
			return;
		}
		files.forEach((dirent,i) => {
			if(dirent.isFile() || dirent.isSymbolicLink()){
				result.push(path.relative(relativeTo, path.resolve(dir, dirent.name)));
			} else if (dirent.isDirectory() && depth) {
				callsRemaining.value++;
				getFiles(
					path.resolve(dir, dirent.name), 
					{depth, relativeTo}, 
					result, 
					callsRemaining, 
					resolver,
					rejector
				);
			}
		});
		callsRemaining.value--;
		if(!callsRemaining.value){
			resolver(result);
		}
	});
}

exports.getFiles = getFiles;

/*
Usage:
getFiles("./",{depth:0, relativeTo:"../../"})
.then(result => console.log(result))
.catch(err => console.log(err));
*/
/*
Usage within module:
const {getFiles} = require("path/to/getfiles.js");
*/
