
/*
	finds the directory that contains
	the search string. If not found, will
	iteratively look upwards until depth 
	is reached. Usage:
	findDir(__dirname, "/node_modules", {depth: 5})
*/
const
	fs = require('fs'),
	path = require('path'),
	findDir = function(
		start,
		search,
		opts = {
			fsConstants: fs.constants.F_OK | fs.constants.R_OK,
			depth: 1
		}
	) {
		return new Promise((res, rej) => {
			for (var i = 0, j = start; i < opts.depth; ++i){
				fs.access(
					path.join(j, search),
					opts.fsConstants,
					((i,j) => (err) => {
							if(!err){
								res(j);
							} else if (i === opts.depth - 1 ) {
								rej(opts.err || err);
							}
						}
					)(i,j)
				);
				j = path.join(j, "..");
			}
		});
	};
exports.findDir = findDir;
