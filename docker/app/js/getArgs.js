
exports.getArgs = function(ARGV){ //process.env.slice(2)
	return {
		nodaemon: (function(){
			let filtered = ARGV.filter(function(arg){
				return this.test(arg);
			},/^(?:-{1,2})?d[ae]{1,3}mon\s*$|^-{1,2}d\s*$/gi);
			return filtered.length 
				? false
				: true
		}()),
		input: (function(){
			let lastIndex = undefined;
			ARGV.forEach(function(arg,i){
				if(this.test(arg)){
					lastIndex = i;
				}
			},/^(?:-{1,2})?input\s*$|^-{1,2}i\s*$/gi);
			return lastIndex === undefined
				? lastIndex
				: ARGV[lastIndex + 1];
		}()),
		mount: (function(){
			let lastIndex = undefined;
			ARGV.forEach(function(arg,i){
				if(this.test(arg)){
					lastIndex = i;
				}
			},/^(?:-{1,2})?mount\s*$|^-{1,2}m\s*$/gi);
			return lastIndex === undefined
				? lastIndex
				: ARGV[lastIndex + 1];
		}())
	};
}
