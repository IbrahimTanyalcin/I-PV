#!/usr/bin/perl
package ipv_modules::config;
use strict;
use warnings;
use utf8;
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use File::Spec qw(catfile file_name_is_absolute catdir);
use File::Path qw(make_path);
use File::Copy qw(copy move cp);
use feature qw(say current_sub);
use Exporter qw(import);
use List::Util qw(max);
use Cwd qw(abs_path);
use lib dirname(abs_path $0);
use ipv_modules::consumeInput qw(consumeInput);
use ipv_modules::char;

our $VERSION = 0.01;

sub new {
	my ($className, $config, $json) = @_;
	my $self = {};
	bless $self, $className;
	$self 
		-> set("config", $config) 
		-> set("configDefined", defined $config)
		-> set("className", $className)
		-> set("json", $json)
		-> set("defErrMsg", "A call to config.pm -> err has been made.\n")
		-> set("defFatalMsg", "A call to config.pm -> fatal error has occured.\n")
		-> set("defQueMsg", "A call to config.pm -> query has been made.\n")
		-> set("defInfoMsg", "A call to config.pm -> info has been made.\n")
		-> set("defRawMsg", "A call to config.pm -> rawMsg has been made.\n")
		-> set("sMarker", "_" x 40)
		-> set("eMarker", "_" x 40)
		-> set("mMarker", "| ")
		-> set(
			"consDefVal", 
			consumeInput(
				["conservation","defVal"], 
				$json,
				{
					"callback" => $self -> conservation -> {defVal}
				}
			)
		)
		-> set(
			"consBarHeight",
			consumeInput(
				["conservation","barHeight"], 
				$json,
				{
					"callback" => $self -> conservation -> {barHeight}
				}
			)
		)
		-> set("relPath","..")
		-> set("absPath", 0)
		-> set("configPath", 0)
		-> set("scriptPath", undef) #will be set later within the main
		-> set("configDir", undef) #similar to above
		-> set("defPaths", { #default paths or path definitions
			defGen => sub {
				my $type = $_[0];
				$self 
					-> {cache} 
					-> {transliterate} 
					-> {bSlash}
					-> (\$type);
				return File::Spec -> catfile(
					$self -> {scriptPath},
					$self -> {relPath},
					"/circos-p/datatracks/",
					$type . ".txt"
				);
			},
			defTemp => sub {
				my $type = $_[0];
				$self 
					-> {cache} 
					-> {transliterate} 
					-> {bSlash}
					-> (\$type);
				return File::Spec -> catfile(
					$self -> {scriptPath},
					$self -> {relPath},
					"/circos-p/templates/",
					$type . ".txt"
				);
			},
			plotConf => sub {
				return File::Spec -> catfile(
					$self -> {scriptPath},
					$self -> {relPath},
					"/circos-p/datatracks/plot.conf"
				);
			},
			circos_templateConf => sub {
				return File::Spec -> catfile(
					$self -> {scriptPath},
					$self -> {relPath},
					"/circos-p/templates/circos_template.conf"
				);
			}
		})
		-> set("cache", {
			transliterate => $self -> transliterate,
			path => $self -> path,
			perms => $self -> perms,
			variation => $self -> variation
		})
		-> set("circosOutputPerms", undef)
		-> set("datatracksPerms", undef)
		-> set("hasVariations", 0);
	return $self;
} 

sub set {
	my $self = shift;
	my ($name, $ref) = @_;
	$self ->  {$name} = $ref;
	return $self;
}

sub ask {
	my ($self, $undefined, $json) = @_;
	return $self -> {configDefined} ? 0 : 1;
}

sub path {
	my ($self, $_outputs) = ($_[0], {});
	return {
		callback => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> fatal([
					"You have not specified a path key explicitly.",
					"If you want to use relative paths,",
					"use an empty string ('') as path key.",
					"If you want every path to be relative to the",
					"config file, then use 'config' as path key.",
					"If you want absolute paths, then use 'absolute'."
				]);
			} elsif ($retVal =~ /^\s*absolute\s*$/gi) {
				$self -> set("absPath", 1);
			} elsif ($retVal =~ /^\s*config\s*$/gi) {
				$self -> set("configPath", 1);
			}
			return $retVal;
		},
		setRelPath => sub {
			my $relPath = $_[0];
			$self 
				-> {cache} 
				-> {transliterate} 
				-> {bSlash}
				-> (\$relPath);
			if (!defined $relPath){
				die "setRelPath expects a non-null argument.\n";
			}
			return $self -> set("relPath", $relPath);
		},
		getBasePath => sub {
			my $varPart = $_[0] || "";
			$self -> {cache} -> {transliterate} -> {bSlash} -> (\$varPart);
			if ($self -> {absPath}) {
				$self -> fatal([
					"calls to getBasePath only should be made when",
					"path parameter is set to config or empty string",
				]);
			} elsif ($self -> {configPath}) {
				return $self -> {configDir};
			} else {
				return File::Spec -> catdir(
					$self -> {scriptPath},
					$self -> {relPath},
					$varPart
				);
			}
		},
		input => sub {
			my ($input, $type) = @_;
			$type = $type || "input";
			$self 
				-> {cache} 
				-> {transliterate} 
				-> {bSlash}
				-> (\$input);
			if($self -> {absPath}) {
				$input = File::Spec -> catfile(
					dirname($input), 
					basename($input)
				);
				if(!(File::Spec -> file_name_is_absolute($input))){
					$self -> fatal([
						"the path parameter you defined for your",
						"$type doesn't seem to be an absolute one",
					]);
				}
				return $input;
			}
			return File::Spec -> catfile(
				$self -> {cache} -> {path} -> {getBasePath} -> ("/circos-p/Input/"),
				$input
			);
		},
		datatracks => sub {
			my $type = $_[0];
			if (!defined $type){
				$self -> fatal([
					"a call to consumer.path.datatracks has been",
					"made, however the type parameter is missing."
				]);
			}
			my $retVal = $self -> {defPaths} -> {$type};
			if (!defined $retVal) {
				return $self -> {defPaths} -> {defGen} -> ($type);
			}
			return $retVal -> ($type);
		},
		templates => sub {
			my $type = $_[0];
			if (!defined $type){
				$self -> fatal([
					"a call to consumer.path.templates has been",
					"made, however the type parameter is missing."
				]);
			}
			my $retVal = $self -> {defPaths} -> {$type};
			if (!defined $retVal) {
				return $self -> {defPaths} -> {defTemp} -> ($type);
			}
			return $retVal -> ($type);
		},
		outputWithExt => sub {
			my $type = $_[0];
			my $outDir;
			my $mkDir = 0;
			if ($self -> {configDefined}) {
				$mkDir = consumeInput(
					["circos","mkdir"], 
					$self -> {json}
				);
				$outDir = consumeInput(
					["circos","output"], 
					$self -> {json}
				);
				if ($outDir) {
					$self 
						-> {cache} 
						-> {transliterate} 
						-> {bSlash}
						-> (\$outDir);
					if ($self -> {absPath}){
						if (!(File::Spec -> file_name_is_absolute($outDir))) {
							$self -> fatal([
								"the circos.output parameter you defined for",
								"$type doesn't seem to be an absolute one",
							]);
						}
					} else {
						$outDir = File::Spec -> catdir(
							$self -> {cache} -> {path} -> {getBasePath} -> ("/circos-p/Output/"),
							$outDir
						);
					}
					# This seems like a bad idea, apparently it depends on filesystem: 
					# https://stackoverflow.com/questions/6456137/using-the-d-test-operator-in-perl
					# check tchrist's comment
					# if (!(-d $outDir)) {
						# $self -> fatal([
							# "the circos.output path is not a directory"
						# ]);
					# }
				}
			}
			$outDir = $outDir || File::Spec -> catdir(
				$self -> {scriptPath},
				$self -> {relPath},
				"/circos-p/Output/"
			);
			if (!(-e $outDir)){
				if (!$mkDir) {
					$self -> fatal([
						"circos.output directory does not exist,",
						"circos.mkdir must be set to true for it",
						"to be created."
					]);
				}
				make_path($outDir, {error => \my $mkPathErr});
				if ($mkPathErr && @$mkPathErr){
					$self -> fatal([
						"An error occured while creating paths,",
						"see below:"
					]);
					say Dumper $mkPathErr;
				}
			}
			$self 
				-> {cache} 
				-> {transliterate} 
				-> {bSlash}
				-> (\$type);			
			my $fileName = File::Spec -> catfile(
				$outDir,
				$type
			);
			return ${$_outputs}{$fileName} = $fileName;
		},
		allOutputs => sub {
			#circos.png is created by circos by default
			#it has be manually called to create entry
			$self -> {cache} -> {path} -> {outputWithExt} -> ("circos.png");
			return [grep {defined  ${$_outputs}{$_}} keys %{$_outputs}];
		},
		outputDir => sub {
			my $mockFile = $self -> path -> {outputWithExt} -> ("mock.txt");
			return dirname($mockFile);
		},
		datatracksDir => sub {
			my $mockFile = $self -> path -> {datatracks} -> ("mock");
			return dirname($mockFile);
		},
		datatracksCustomDir => sub {
			my $field = $_[0];
			my $outDir;
			my $mkDir = 0;
			if ($self -> {configDefined}) {
				$mkDir = consumeInput(
					["datatracks","mkdir"], 
					$self -> {json}
				);
				$outDir = consumeInput(
					["datatracks", $field], 
					$self -> {json}
				);
				if ($outDir) {
					$self 
						-> {cache} 
						-> {transliterate} 
						-> {bSlash}
						-> (\$outDir);
					if ($self -> {absPath}){
						if (!(File::Spec -> file_name_is_absolute($outDir))) {
							$self -> fatal([
								"the datatracks.$field parameter you defined",
								"doesn't seem to be an absolute one",
							]);
						}
					} else {
						$outDir = File::Spec -> catdir(
							$self -> {cache} -> {path} -> {getBasePath} -> ("/circos-p/datatracks/"),
							$outDir
						);
					}
				}
			}
			$outDir = $outDir || File::Spec -> catdir(
				$self -> {scriptPath},
				$self -> {relPath},
				"/circos-p/datatracks/"
			);
			if (!(-e $outDir)){
				if (!$mkDir) {
					$self -> fatal([
						"datatracks.$field directory does not exist,",
						"datatracks.mkdir must be set to true for it",
						"to be created."
					]);
				}
				make_path($outDir, {error => \my $mkPathErr});
				if ($mkPathErr && @$mkPathErr){
					$self -> fatal([
						"An error occured while creating paths,",
						"see below:"
					]);
					say Dumper $mkPathErr;
				}
			}
			return $outDir;
		},
		allDatatracks => sub {
			return [
				$self -> path -> {datatracks} -> ("karyotype"),
				$self -> path -> {datatracks} -> ("protein_sequence"),
				$self -> path -> {datatracks} -> ("scatter"),
				$self -> path -> {datatracks} -> ("text_plot_missense"),
				$self -> path -> {datatracks} -> ("tile_plot"),
				$self -> path -> {datatracks} -> ("modict_plot"),
				$self -> path -> {datatracks} -> ("highlights"),
				$self -> path -> {datatracks} -> ("connector"),
				$self -> path -> {datatracks} -> ("connector_text"),
				$self -> path -> {datatracks} -> ("plot"),
				$self -> path -> {datatracks} -> ("plotConf")
			];
		},
		cleanFiles => sub {
			foreach my $file (@{$_[0]}) {
				if(-e $file) {
					unlink $file 
					or warn join(
						"\n",
						@{[
							"Could not remove $file:",
							"$!",
							""
						]}
					);
				}
			}
		},
		#does NOT auto tr backslashes
		copyFiles => sub {
			my ($files, $directory) = @_;
			foreach my $file (@{$files}) {
				if(-e $file) {
					my $bName = basename($file);
					my $nPath = File::Spec -> catfile(
						$directory,
						$bName
					);
					copy(
						$file,
						$nPath
					) or warn join(
						"\n",
						@{[
							"Could not copy $file:",
							"$!",
							""
						]}
					);
				}
			}
		},
		copyFilesCp => sub {
			my ($files, $directory) = @_;
			foreach my $file (@{$files}) {
				if(-e $file) {
					my $bName = basename($file);
					my $nPath = File::Spec -> catfile(
						$directory,
						$bName
					);
					cp(
						$file,
						$nPath
					) or warn join(
						"\n",
						@{[
							"Could not cp $file:",
							"$!",
							""
						]}
					);
				}
			}
		},
		#does NOT auto tr backslashes
		moveFiles => sub {
			my ($files, $directory) = @_;
			foreach my $file (@{$files}) {
				if(-e $file) {
					my $bName = basename($file);
					my $nPath = File::Spec -> catfile(
						$directory,
						$bName
					);
					move(
						$file,
						$nPath
					) or warn join(
						"\n",
						@{[
							"Could not move $file:",
							"$!",
							""
						]}
					);
				}
			}
		},
		circos => sub {
			my $circos;
			if ($self -> {configDefined}) {
				$circos = consumeInput(
					["circos", "path"], 
					$self -> {json}
				);
				if ($circos) {
					$self 
						-> {cache} 
						-> {transliterate} 
						-> {bSlash}
						-> (\$circos);
					if ($self -> {absPath}){
						if (!(File::Spec -> file_name_is_absolute($circos))) {
							$self -> fatal([
								"the circos.path parameter you defined",
								"doesn't seem to be an absolute one",
							]);
						}
					} else {
						$circos = File::Spec -> catfile(
							$self -> {cache} -> {path} -> {getBasePath} -> ("../circos/bin/"),
							$circos
						);
					}
				}
			}
			$circos = $circos || File::Spec -> catfile(
				$self -> {scriptPath},
				$self -> {relPath},
				"../circos/bin/circos"
			);
			return $circos;
		}
	};
}

sub fasta {
	my $self = $_[0];
	return {
		callback => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					You have not specified fasta file of 
					your protein sequence. Your config json 
					has to include the field 'proteinFileName'
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		}
	};
}

sub conservation {
	my $self = $_[0];
	return {
		callback => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				# Below will force quit if 
				# no conservation file is provided
				# $self -> err([
					# "You have not specified a conservation file.",
					# "Your config json has to include the field",
					# $self -> stringifyFields($fields)
				# ]);
				
			}
			$self -> set("consFile", !!$retVal);
			return $retVal;
		},
		barHeight => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& defined $retVal
				&& $retVal !~ /^\s*[0-9]\s*$/gi
			){
				# There is currently no way to fine tune bar 
				# height if one is invoking the script from 
				# CLI without json, will get default value of 
				# 4
				$self -> err([
					$self -> stringifyFields($fields) 
					. "must be an integer 0 - 9"
				]);
			}
			return defined $retVal ? $self -> trim($retVal) : 4;
		},
		defVal => sub {
			my ($retVal, $json, $fields) = @_;
			return defined $retVal ? $retVal : "Unknown";
		}
	};
}

sub domain {
	my $self = $_[0];
	return {
		start => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					Your config json is missing 'start'
					field of the domain object
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		},
		end => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					Your config json is missing 'end'
					field of the domain object
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		},
		assign => sub {
			my ($retVal, $json) = @_;
			my $err;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				($err = qq{
					Your config json is missing 'domains'
					field which is an array of objects
				}) =~ s/^\t+//gm;
				die $err;
			} elsif (
				$self -> {configDefined}
				&& ref $retVal ne "ARRAY"	
			) {
				($err = qq{
					'domains' field has to 
					be an array of objects
				}) =~ s/^\t+//gm;
				die $err;
			} elsif ($self -> {configDefined}) {
				return scalar @{$retVal} >= 1 ? "y" : "n"; 
			}
			return $retVal;
		},
		name => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					Your config json is missing 'name'
					field of the domain object
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		},
		color => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					Your config json is missing 'color'
					field of the domain object
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		},
		nextDomain => sub {
			my ($retVal, $json) = @_;
			my $err;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				($err = qq{
					Your config json is missing 'domains'
					field which is an array of objects
				}) =~ s/^\t+//gm;
				die $err;
			} elsif ($self -> {configDefined}) {
				shift @{$retVal};
				return scalar @{$retVal} >= 1 ? "y" : "n";
			}
			return $retVal;
		}
	};
}

sub mrna {
	my $self = $_[0];
	return {
		callback => sub {
			my ($retVal, $json) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					You have not specified mrna file of 
					your cDNA sequence. Your config json 
					has to include the field 'mrnaFileName'
				}) =~ s/^\t+//gm;
				die $err;
			}
			return $retVal;
		}
	};
}

sub protein {
	my $self = $_[0];
	return {
		name => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				(my $err = qq{
					Your json needs to have the field 'name' which
					will be shown at the bottom of your html output
				}) =~ s/^\t+//gm;
				die $err;
			}
			if ($retVal =~ ipv_modules::char::oneof([
				qw(\ / . ? * ¥)
			])) {
				#https://docs.microsoft.com/en-us/windows/win32/intl/character-sets-used-in-file-names
				$self -> fatal([
					"field " . $self -> stringifyFields($fields),
					"requires legit filenames that lack",
					"backslash, forward slash, dot, question",
					"mark, star and Yen symbols."
				]);
			}
			return $retVal;
		}
	};
}

sub variation {
	my ($self, $colBaseChange) = ($_[0], undef);
	my $valNumber = sub {
		my ($retVal, $json, $fields) = @_;
		my $err = $self -> stringifyFields($fields) 
			. "must be an integer";
		my $isNumber = +$retVal =~ /^\d+$/gi;
		if ($self -> {configDefined}){
			if(!$isNumber){
				$self -> err([$err]);
			}
			return $retVal;
		}
		my $testNumber = sub {
			$self -> query($err . ", retry");
			$retVal = <STDIN>;
			chomp $retVal;
			if (+$retVal !~ /^\d+$/gi){
				__SUB__ -> ();
			} else {
				$isNumber = 1;
			}
		};
		if(!$isNumber){
			$testNumber -> ();
		}
		return $retVal;
	};
	my $noUndefOrEmpty = sub {
		my ($retVal, $json, $fields) = @_;
		my $err = $self -> stringifyFields($fields) 
			. "must not be undefined or an empty string";
		my $isUndefOrEmpty = !defined $retVal || $retVal eq "";
		if ($self -> {configDefined}){
			if($isUndefOrEmpty){
				$self -> err([$err]);
			}
			return $retVal;
		}
		my $testUndefOrEmpty = sub {
			$self -> query($err . ", retry");
			$retVal = <STDIN>;
			chomp $retVal;
			if (!defined $retVal || $retVal eq ""){
				__SUB__ -> ();
			} else {
				$isUndefOrEmpty = 0;
			}
		};
		if($isUndefOrEmpty){
			$testUndefOrEmpty -> ();
		}
		return $retVal;
	};
	my $fallBackToThisIf = sub {
		my ($fallbackVal, $conditionSub, $noFallbackVal) = @_;
		if(ref($conditionSub) ne "CODE"){
			$self -> fatal([
				"2nd argument to fallBackToThisIf must be",
				"a reference to a function."
			]);
		}
		return sub {
			my ($retVal, $json, $fields) = @_;
			if(&{$conditionSub}(@_)) {
				if(ref($fallbackVal) eq "CODE") {
					return &{$fallbackVal}(@_);
				}
				return $fallbackVal;
			}
			if(defined $noFallbackVal){
				if(ref($noFallbackVal) eq "CODE") {
					return &{$noFallbackVal}(@_);
				}
				return $noFallbackVal;
			}
			return $retVal;
		}
	};
	my $fallBackToColBaseChange = sub {
		my ($retVal, $json, $fields) = @_;
		if(!defined $retVal) {
			if(!defined $colBaseChange){
				$self -> fatal([
					"'colBaseChange' must be defined",
					"before a call for " . $self -> stringifyFields($fields)
				]);
			}
			$self -> info([
				$self -> stringifyFields($fields) . " was not specified,",
				"fallingback to col#" . $colBaseChange
			]);
			return 1; #fallback
		}
		return 0; #keep original value
	};
	return {
		callback => sub {
			my ($retVal, $json, $fields) = @_;
			my $err;
			#if (
			#	$self -> {configDefined} 
			#	&& !defined $retVal
			#){
			#	$self -> err([
			#		"Your json needs to have the field",
			#		$self -> stringifyFields($fields)
			#	]);
			#}
			return $retVal;
		},
		fileName => &{$fallBackToThisIf}(
			"NA",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming there are no variations to plot."
					]);
					return 1;
				}
				return 0;
			}
		),
		skipHeader => &{$fallBackToThisIf}(
			"y",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming a header exists."
					]);
					return 1;
				}
				return 0;
			},
			sub {
				my ($retVal, $json, $fields) = @_;
				my $err;
				if ($self -> {configDefined}){
					if (!defined $retVal){
						$self -> err([
							"Your json needs to have the field",
							$self -> stringifyFields($fields)
						]);
					} elsif (+$retVal !~ /^\d+$/gi) {
						$self -> err([
							$self -> stringifyFields($fields),
							"needs to be an integer"
						]);
					}
					return "y";
				}
				return $retVal;
			}
		),
		skipHeaderCount => &{$fallBackToThisIf}(
			1,
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming the header is a single line."
					]);
					return 1;
				}
				return 0;
			},
			sub {return &{$valNumber}(@_);}
		),
		colBaseChange => sub {
			return $colBaseChange = &{$valNumber}(@_);
		},
		colSubsType => &{$fallBackToThisIf}(
			sub {return $colBaseChange;},
			$fallBackToColBaseChange,
			sub {return &{$valNumber}(@_);}
		),
		colSubsCoords => $valNumber,
		colValStat => &{$fallBackToThisIf}(
			sub {return $colBaseChange;},
			$fallBackToColBaseChange,
			sub {return &{$valNumber}(@_);}
		),
		colBaseChangeStrand => $valNumber,
		colGeneStrand => &{$fallBackToThisIf}(
			"+",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming your gene is on the plus strand."
					]);
					return 1;
				}
				return 0;
			},
			sub {
				my ($retVal, $json, $fields) = @_;
				my $err;
				if ($self -> {configDefined}){
					if(!defined $retVal){
						$self -> err([
							"Your json needs to have the field",
							$self -> stringifyFields($fields)
						]);
					} elsif ($retVal !~ /^plu|min|pos|neg|[+]|[-]|1|-1/) {
						$self -> err([
							$self -> stringifyFields($fields),
							"has to be one of plu, min, pos, neg, +, -, 1, -1"
						]);
					}
				}
				return $retVal;
			}
		),
		colTranscriptID => $valNumber,
		colPolyphen2 => &{$fallBackToThisIf}(
			"NA",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming you do not have polyphen2 scores."
					]);
					return 1;
				}
				return 0;
			},
			sub {return &{$valNumber}(@_);}
		),
		colSift2 => &{$fallBackToThisIf}(
			"NA",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming you do not have sift scores."
					]);
					return 1;
				}
				return 0;
			},
			sub {return &{$valNumber}(@_);}
		),
		maf => &{$fallBackToThisIf}(
			"NA",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming you do not have Minor Allele Frequencies."
					]);
					return 1;
				}
				return 0;
			},
			sub {return &{$valNumber}(@_);}
		),
		pass => sub {
			my $retVal = shift @_;
			return $retVal;
		},
		separator => &{$fallBackToThisIf}(
			"tab",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal){
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"assuming the file is tab delimited."
					]);
					return 1;
				}
				return 0;
			},
			sub {return &{$noUndefOrEmpty}(@_);}
		),
		transcriptID => &{$fallBackToThisIf}(
			"ProcessAll",
			sub {
				my ($retVal, $json, $fields) = @_;
				if(!defined $retVal) {
					$self -> info([
						$self -> stringifyFields($fields) . " was not specified,",
						"processing all transcripts."
					]);
					return 1; #fallback
				}
				return 0; #keep original value
			}
		)
	};
}

sub markup {
	my $self = $_[0];
	return {
		assign => sub {
			my ($retVal, $json, $fields) = @_;
			my $err;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				# Erring here will force people to use markups
				# $self -> err([
					# "Your json needs to have the field",
					# $self -> stringifyFields($fields),
					# "which is an array of objects"
				# ]);
				return "n";
			} elsif (
				$self -> {configDefined}
				&& ref $retVal ne "ARRAY"	
			) {
				$self -> err([
					$self -> stringifyFields($fields) 
					. " field has to be an array of objects"
				]);
			} elsif ($self -> {configDefined}) {
				return scalar @{$retVal} >= 1 ? "y" : "n"; 
			}
			return $retVal;
		},
		start => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your config json is missing",
					"'start' field of the markup object"
				]);
			}
			return $retVal;
		},
		end => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your config json is missing",
					"'end' field of the markup object"
				]);
			}
			return $retVal;
		},
		name => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your config json is missing",
					"'name' field of the markup object"
				]);
			}
			return $retVal;
		},
		prop => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your config json is missing",
					"'prop' field of the markup object"
				]);
			}
			return $retVal;
		},
		color => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your config json is missing",
					"'color' field of the markup object"
				]);
			}
			return $retVal;
		},
		nextMarkup => sub {
			my ($retVal, $json, $fields) = @_;
			my $err;
			if (
				$self -> {configDefined} 
				&& !defined $retVal
			){
				$self -> err([
					"Your json needs to have the field",
					$self -> stringifyFields($fields),
					"which is an array of objects"
				]);
			} elsif ($self -> {configDefined}) {
				shift @{$retVal};
				return scalar @{$retVal} >= 1 ? "y" : "n";
			}
			return $retVal;
		}
	};
}

sub circos {
	my $self = $_[0];
	return {
		run => sub {
			my ($retVal, $json, $fields) = @_;
			my $err;
			if ($self -> {configDefined}){
				if(!defined $retVal || !!$retVal){
					return "continue";
				} else {
					return "exit";
				}
			}
			return $retVal;
		},
		pass => sub {
			my $retVal = shift @_;
			return $retVal;
		}
	};
}

sub stringifyFields {
	my ($self, $fields, $options) = @_;
	if(ref $options ne "HASH") {
		$options = {};
	}
	$options -> {start} = $options -> {start} || "'";
	$options -> {end} = $options -> {end} || "'";
	$options -> {join} = $options -> {join} || "\.";
	return $options -> {start} 
		. join($options -> {join}, @{$fields}) 
		. $options -> {end};
}

sub err {
	my ($self, $msg) = @_;
	$msg = $msg || $self -> {defErrMsg};
	if (ref ($msg) eq "ARRAY"){
		$msg = join("\n", @{$msg}) . "\n";
	}
	if ($self -> {configDefined}) {
		say "config json is fault intolerant,\n"
		. "below is the err message:\n"
		. $self -> {sMarker};
		die ($msg . $self -> {eMarker} . "\n");
	} else {
		print $msg;
	}
}

sub fatal {
	my ($self, $msg) = @_;
	$msg = $msg || $self -> {defFatalMsg};
	if (ref ($msg) eq "ARRAY"){
		$msg = join("\n", @{$msg}) . "\n";
	}
	say "fatal error message:\n" . $self -> {sMarker};
	die ($msg . $self -> {eMarker} . "\n");
}

sub info {
	my ($self, $msg) = @_;
	$msg = $msg || $self -> {defInfoMsg};
	if (ref ($msg) eq "ARRAY"){
		$msg = join("\n" . $self -> {mMarker}, @{$msg}) . "\n";
	}
	say "Info:\n"
	. $self -> {sMarker} . "\n"
	. $self -> {mMarker}
	. $msg 
	. $self -> {eMarker} . "\n";
}

sub rawMsg {
	my ($self, $msg) = @_;
	$msg = $msg || $self -> {defRawMsg};
	if (ref ($msg) eq "ARRAY"){
		$msg = join("\n", @{$msg}) . "\n";
	}
	return $self -> {sMarker} . "\n"
		. $msg 
		. $self -> {eMarker} . "\n";
}

sub static {
	return "ipv_modules::config";
}

sub query {
	my ($self, $msg) = @_;
	$msg = $msg || $self -> {defQueMsg};
	if (ref ($msg) eq "ARRAY"){
		$msg = join("\n", @{$msg}) . "\n";
	}
	if (!($self -> {configDefined})) {
		print $msg;
	} 
}

sub trim {
	my ($self, $str) = @_;
	$str =~ s/^\s+|\s+$//g;
	return $str;
}

sub transliterate {
	my $self = $_[0];
	return {
		lfCr => sub {
			my $strRef = $_[0];
			if (uc(ref $strRef) ne "SCALAR"){
				$self -> fatal([
					"consumer -> transliterate -> lfCr",
					"expects a reference to a scalar",
				]);
			}
			${$strRef} =~ tr/\N{U+0D}\N{U+0A}//d;
			return $strRef;
		},
		bSlash => sub {
			my $strRef = $_[0];
			if (uc(ref $strRef) ne "SCALAR"){
				$self -> fatal([
					"consumer -> transliterate -> bSlash",
					"expects a reference to a scalar",
				]);
			}
			${$strRef} =~ tr/\N{U+5C}/\N{U+2F}/;
			return $strRef;
		}
	}
}

sub autoflush {
	my $self = $_[0];
	return {
		callback => sub {
			my ($retVal, $json, $fields) = @_;
			if (
				$self -> {configDefined} 
				&& defined $retVal
			){
				return $retVal;
				
			}
			return $|;
		}
	};
}

sub perms {
	my $self = $_[0];
	my $valOctal = sub {
		my ($retVal, $json, $fields) = @_;
		$retVal = $self -> trim($retVal);
		if ($retVal =~ m/^0[0-7]{3}$/gi){
			return $retVal;
		}
		$self -> fatal([
			"field " . $self -> stringifyFields($fields),
			"needs to match ^0[0-7]{3}\$"
		]);
	};
	return {
		checkPerm => sub {
			my ($retVal, $json, $fields) = @_;
			if(!defined $retVal){
				return;
			}
			return &{$valOctal}(@_);
		},
		setPerm => sub {
			my ($files, $perm) = @_;
			$files = [grep {-e $_} @{$files}];
			if(!(@{$files})){
				return;
			}
			if(!defined $perm){
				$self -> info([
					"Leaving default permissions for",
					map {basename($_)} @{$files}
				]);
				return;
			}
			$self -> info([
				"Setting permissions to " . oct($perm) . "(base10) for",
				map {basename($_)} @{$files}
			]);
			my $nrSuccess = chmod oct($perm), @{$files};
			if ($nrSuccess) {
				say "$nrSuccess file(s) had their perms changed.\n";
			} else {
				say "chmod did not change any file perms.\n";
			}
		}
	};
}

sub preflight {
	my $self = $_[0];
	$self -> set(
		"datatracksPerms",
		consumeInput(
			["datatracks","perms"], 
			$self -> {json},
			{
				"callback" => $self -> {cache} -> {perms} -> {checkPerm}
			}
		)
	);
	$self -> set (
		"circosOutputPerms",
		consumeInput(
			["circos","perms"], 
			$self -> {json},
			{
				"callback" => $self -> {cache} -> {perms} -> {checkPerm}
			}
		)
	);
}

qq{
	0042 0065 006e 0020 0079 006f 006c 0063 0075 006c 0075 006b 0020 0075 0073 0074 0061 0073 0131 0079 0131 006d
	0048 0065 0072 0020 0067 0065 006d 0069 006e 0069 006e 0020 0074 0061 0079 0066 0061 0073 0131 0079 0131 006d
	0042 0065 006e 0069 006d 0020 0064 00fc 006e 0079 0061 006d 0020 006b 0075 015f 0062 0061 006b 0131 015f 0131
	0042 0065 006e 0020 0067 0065 006d 0069 006e 0069 006e 0020 006d 0061 0072 0074 0131 0073 0131 0079 0131 006d
	                                             0046 0065 0072 0068 0061 006e 0020 015e 0065 006e 0073 006f 0079
};