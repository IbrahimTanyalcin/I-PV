# Readme

## 🚢 Running with Docker

I-PV has a docker image which you can pull and execute without installing dependencies. Head over to [![Readme-Docker](https://img.shields.io/badge/ipv-docker-azure
)](https://github.com/IbrahimTanyalcin/I-PV/tree/master/docker) for details.

## 🚦 Testing

`> npm run test`

## 📂 Folder Structure

When you do `npm i ibowankenobi-i-pv` or clone the repo, inside `i-pv` folder you will find the following files/folders.

```shell
+---circos-p
|   +---datatracks
|   |
|   +---Input
|   |
|   +---Output
|   |   
|   \---templates
|
\---script
    |   HGVStoBiomart.pl
    |   invokeCircos.pl
    |   SNPtoAA.pl
    |   vcfToTsv_v3.pl
    |
    \---ipv_modules
```
## 🏃 Running the script

To generate the plot, run:

```perl
perl SNPtoAA.pl
```
This will start an interactive Q&A session.

As of version 2.0, you can also do:

```perl
perl SNPtoAA.pl --config path/your/config.json
```
This will automatically generate the plot based on parameters provided in the config json.

For both cases, your cwd does not matter.

## ⚠ Directions for Usage

Do:

`> git clone https://github.com/IbrahimTanyalcin/I-PV.git`

Or: 

`> npm i ibowankenobi-i-pv`

If you will I-PV in interactive mode, run:

`> perl SNPtoAA.pl`

For the above script to work, make sure you placed your files under `circos-p/input`:
- mRNA sequence (fasta)
- protein sequence (fasta)
- conservation scores (numbers separated by newlines)
- variation (biomart-ensembl format)

If you want to use I-PV as a part of pipeline or without interactive CLI, run:

`> perl SNPtoAA.pl --config path/to/your.json`

Outputs are located under `./circos-p/Output`, unless specified otherwise in a `config.json`.

Datatracks are located under `./circos-p/datatracks` unless overridden by `config.json`. (These are instructions for circos, to be used later with `invokeCircos` script.)

## 📚 Dependencies

Required NodeJS version:
- ^12.13.0 (^10.X.X should be ok)

I-PV NodeJS dev dependencies
- ^7.0.3 cross-env 
  
Required Perl version
- 5.22.0 (5.26.X, even up to 5.34.X should be ok)

I-PV Perl modules (*[version string, module name]*)
- 2.158 Data::Dumper
- 1.25 IPC::System::Simple
- 2.30 File::Copy
- 2.85 File::Basename
- 3.56 File::Spec
- 2.09 File::Path
- 2.45 Getopt::Long
- 1.51 FindBin
- 3.01 JSON::XS
- 1.42 List::Util
- 3.56 Cwd

Circos Perl modules *[version, module name]*
- 1.36 Carp
- 0.38 Clone
- 2.58 Config::General
- 3.56 Cwd
- 2.158 Data::Dumper
- 2.54 Digest::MD5
- 2.85 File::Basename
- 3.56 File::Spec::Functions
- 0.2304 File::Temp
- 1.51 FindBin
- 0.39 Font::TTF::Font
- 2.56 GD
- 0.2 GD::Polyline
- 2.45 Getopt::Long
- 1.16 IO::File
- 0.412 List::MoreUtils
- 1.42 List::Util
- 0.01 Math::Bezier
- 1.9997 Math::BigFloat
- 0.07 Math::Round
- 0.08 Math::VecStat
- 1.03 Memoize
- 1.53 POSIX
- 1.18 Params::Validate
- 1.67 Pod::Usage
- 2 Readonly
- 2013031301 Regexp::Common
- 2.64 SVG
- 1.19 Set::IntSpan
- 1.6611 Statistics::Basic
- 2.53 Storable
- 1.20 Sys::Hostname
- 2.03 Text::Balanced
- 0.59 Text::Format
- 1.9726 Time::HiRes

## ℹ Config options

Here is a minial `config.json` example:

```json
{
	"path": "  config  ",
	"proteinFileName": "testInput/fasta.txt",
	"mrnaFileName": "testInput\\mRNA.txt",
	"name": "NFKB",
	"domains": [
		{
			"start": 50,
			"end": 126,
			"name": "domain_X",
			"color": "vdred"
		}
	]
}
```

And below is a bit more complicated `config.json`. In fact, when when you run:

`> npm run test` 

the command above in turn runs:

`> perl path/to/root/i-pv/script/SNPtoAA.pl --config ./below/config.json`

and below json config is passed to `SNPtoAA.pl`: 

```json
{
	"path": "",
	"autoflush": 1,
	"proteinFileName": "testInput/fasta.txt",
	"mrnaFileName": "testInput\\mRNA.txt",
	"conservation":{
		"consFileName": "testInput\\conservation.txt",
		"barHeight": 0,
		"defVal": "Hmm"
	},
	"name": "NFKB",
	"domains": [
		{
			"start": 50,
			"end": 126,
			"name": "domain_X",
			"color": "vdred"
		},
		{
			"start": 350,
			"end": 460,
			"name": "domain_Y",
			"color": "lblue"
		}
	],
	"variation":{
		"format": "ensembl",
		"fileName": "testInput\\mart_export.txt",
		"skipHeader": 1,
		"separator": "tab",
		"colBaseChange": 4,
		"colSubsType": 4,
		"colSubsCoords": 8,
		"colValStat": 4,
		"colBaseChangeStrand": 3,
		"colGeneStrand": "+",
		"transcriptID": "ENST00000505458",
		"colTranscriptID": 6,
		"colPolyphen2": 10,
		"colSift2": 11,
		"maf": 5
	},
	"markups": [
		{
			"start": 60,
			"end": 125,
			"name": "some_region",
			"prop": "prop_x",
			"color": "magenta"
		}
	],
	"circos": {
		"run": 1,
		"path": "",
		"output": "./testOutput/output",
		"mkdir": 1
	},
	"datatracks": {
		"cleanup": 1,
		"mkdir": 1,
		"move": "../Output/testOutput/datatracks"
	}
}
```

For other examples, check `sample-configs` folder.

### _path_ 

| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

You probably would want this option to be set to `"config"`.

- Accepts empty string `""`, `"absolute"` or `"config"` or a `path string`. Empty string means rest of the path parameters are relative as follows:

| Parameter        | Relative to | 
| ------------- |:-------------:|
| proteinFileName      | root/i-pv/circos-p/Input |
| mrnaFileName      | root/i-pv/circos-p/Input      |
| conservation      | root/i-pv/circos-p/Input      |
| variation.fileName | root/i-pv/circos-p/Input      |
| circos.path | root/circos/bin      |
| datatracks.move | root/i-pv/circos-p/datatracks     |
| datatracks.copy | root/i-pv/circos-p/datatracks     |

- If path is "absolute", then paths should look like:

`D:\\path\\to\\your/mRNA.txt`

You can use a mix of backslashes and forward slashes, they are auto transliterated to forward slashes in all OS. 

- If the path is "config", the all the paths are relative to the config file.

- If path is a legitimate `path string` such as `a/b/c` then it means result of `path.join("path/to/SNPtoAA.pll", "a/b/c")` points to `root/i-pv/`. Use this option **ONLY** if you move `SNPtoAA.pl` somewhere else, which you normally would not do.

### _autoflush_

| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Truthy |

Makes sure that if perl is not piped to `STDOUT`, it is not buffered as default. Set this to a truthy value such as 1 if you are using I-PV as a part of pipeline, thus invoking it through another script

### _proteinFileName_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Path to fasta file of your amino acid sequence.

### _mrnaFileName_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Path to fasta file of your mRNA sequence.

### _conservation_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Object |

Use this parameter if you have a conservation file of single column of numbers or you want to change the default bar height.

### _conservation.consFileName_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String |

Path to your conservation file, if any.

### _conservation.barHeight_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

Change this to alter bar height that is drawn when no conservation file is given. Default value is 4. Provide a value that can be converted to 0-9.

### _conservation.defVal_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String |

Change this to alter the text that is shown when you mouseover a conservation scores. Default is the conservation score or empty string if no conservation file was provided.

### _name_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

This will be the name of the output file and the label that is shown when output html is opened. Characters `\ / . ? * ¥` should **NOT** be used.

### _domains_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | Array of Object(s) |

Use this parameter if you want to label certain parts of your protein. You need to have at least 1 domain labelled. 

### _domains[].start_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

Marks the start.

### _domains[].end_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

Marks the end.

### _domains[].name_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Shows the name when mouseover is triggered.

### _domains[].color_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Gives the specified color to the domain. Standard circos colors + additional colors inside `circos-p/templates/custom_preset.conf`

### _variation_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Object |

Use this parameter to mark column number of your variation file (should be similar to what you download from [`Biomart Ensembl Variation`](https://www.ensembl.org/biomart/martview/) as `mart_export.txt`). Column numbers start from 1.

### _variation.format_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String |

Specifies the format of the variation file, which is "ensembl" by default. Setting this to something else does not yet effect anything.

### _variation.fileName_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String |

Path to the variation file for your protein.

### _variation.skipHeader_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

The number of lines to be skipped in your variation file. This is usually 1, which is the header itself. Defaults to 1.

### _variation.separator_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String |

The separator of the file. Case-sensitive "tab", "whitespace", "semicolon" and "space" is supported. If none of these match, the `String` value of the parameter will be used as separator. Defaults to `"tab"`.

### _variation.colBaseChange_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

The column number where the ancesteral and alternative alleles are separated by a forward slash (eg.A/G,C/T/A..)

### _variation.colSubsType_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

The column number where substitution type is specified such as "missense", "synonymous" etc. If this does not exist, provide the same col number as `colBaseChange`. Defaults to the column entered for `colBaseChange`.

### _variation.colSubsCoords_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

Col number for substitution coordinates. Choose the "Coding Start" column.

### _variation.colValStat_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

Vaidation Status column number that states "Validated", "Not_Validated" etc. Useful for files obtained from Alamut Visual. If does not exist, provide the same col number as `colBaseChange`. Defaults to the column entered for `colBaseChange`.

### _variation.colBaseChangeStrand_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

Strand of the change. Has to match `/^plu|min|pos|neg|[+]|[-]|1|-1/`

### _variation.colGeneStrand_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

Strand of the gene/transcript. Has to match `/^plu|min|pos|neg|[+]|[-]|1|-1/`. Defaults to `"+"`.

### _variation.transcriptID_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

The transcript id to filter for. Use "ProcessAll" (case-sensitive) to process all rows. Defaults to `"ProcessAll"`.

### _variation.colTranscriptID_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

The column where your transcript IDs are located. Meaningful if and only if defined and `transcriptID` is NOT `"ProcessAll"`.

### _variation.colPolyphen2_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

The column where your PolyPhen2 scores are located. If not available, use enter "NA". Defaults to `"NA"`.

### _variation.colSift2_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

The column where your Sift scores are located. If not available, use enter "NA". Defaults to `"NA"`.

### _variation.maf_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

The column where your MAF(minor allele frequency) are located. If not available write enter "NA". Defaults to `"NA"`.

### _markups_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Array of Object(s) |

Use this parameter if you want to mark certain regions of your sequence.

### _markups[].start_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | Array of Object(s) |

Same as `domains[].start`.

### _markups[].end_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String \| Number |

Same as `domains[].end`.

### _markups[].name_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Same as `domains[].name`.

### _markups[].prop_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

All of the markup objects with the same `prop` will receive the color of the last markup object with that `prop`. If you want to keep it simple, give a unique `prop` to every markup object. Removing this propery will result in black `color` regardless of the `color` property.

### _markups[].color_
| Optionality        | Type | 
| ------------- |:-------------:|
| Mandatory      | String |

Same as `domains[].color`.

### _circos_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Object |

Configure circos related configs.

### _circos.run_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number |

If it is a falsey value, like `0`, input files will be processed and datatracks will be generated without running circos. Afterwards, you have to run circos yourself or run `invokeCircos.pl`. Default is `1`.

### _circos.path_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

`circos.path` should point to the circos script to be executed.

If empty string, then it uses the default circos inside the `circos` folder that comes with the repo. 

If, config.json's `path` is an empty string (which means relative paths are used), and `circos.path` is a valid path string, than the path is interpreted relative to `root/circos/bin` where `root` is the repo's directory. 

If config.json's `path` is `"absolute"`, then `circos.path` is expected to be a valid absolute path string. 

If config.json's `path` is `"config"`, then `circos.path` is expected be relative to the config file. 

Default is an empty string which means even if config.json's `path` is `"config"`, as long as `circos.path` is NOT explicity specified, it will fallback to the default circos included in the repo.

### _circos.output_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

If empty string or falsey, then it uses the default `circos-p/Output` folder that comes with the repo. 

If, config.json's `path` is an empty string (which means relative paths are used), and `circos.output` is a valid path string, than the path is interpreted relative to `root/i-pv/circos-p/Output/` where `root` is the repo's directory.

If config.json's `path` is `"absolute"`, then `circos.output` is expected to be a valid absolute path string. 

If config.json's `path` is `"config"`, then `circos.output` is expected be relative to the config file. 

Default is an empty string. Which means if you do not specify this parameter explicitly, then the outputs will go to `root/i-pv/circos-p/Output/`.

### _circos.mkdir_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

Used in conjuction with `circos.output`. If `circos.output` points to folders that does not yet exist, `circos.mkdir` permits the perl script to create them. Otherwise an error will be thrown. Default value is `undef`, which means new folders are NOT created.

### _circos.cleanup_

| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

Removes all supplementary outputs such as `.svg` and `.txt` files and leaves only the `.html` file. Truthy values such as `1` or `"1"` will turn it on whereas falsey values such as `0` or `"0"` will turn it off. Defaults to `0`;

### _circos.perms_

| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String   |

Sets the permissions on the output files as the current user. Parameter must match the regex `^0[0-7]{3}$`. Do not provide bare values such as `0755` but instead provide `"0755"`. As these permissions are not directly transferable between Linux and Windows, only a select few permission values such as `"0444"` work on Windows. Default behavior depends on OS and current user. 

### _datatracks_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | Object |

Configure datatracks related configs.

### _datatracks.cleanup_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String \| Number  |

Datatracks files are always created under `root/circos-p/datatracks`. Once circos uses them to generate the html output, you might want to delete them. In that case `datatracks.cleanup` should have a truthy value. Default is `0`.

### _datatracks.move_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

If empty string or falsey nothing is done. If, config.json's `path` is an empty string (which means relative paths are used), and `datatracks.move` is a valid path string, than the path is interpreted relative to `root/i-pv/circos-p/datatracks/` where `root` is the repo's directory. If config.json's `path` is `"absolute"`, then `datatracks.move` is expected to be a valid absolute path string. Default is 0, which means files are left at `circos-p/datatracks` and are not moved.

### _datatracks.copy_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

Similar to `datatracks.move` but instead files are copied.

### _datatracks.mkdir_
| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String  |

Similar to `circos.mkdir`. Determines whether `datatracks.move` and `datatracks.copy` directives are allowed to create folders or not.

### _datatracks.perms_

| Optionality        | Type | 
| ------------- |:-------------:|
| Optional      | String   |

Similar to `circos.perms`.


## 📑 Other Scripts

There are 4 main scripts inside the `script` folder. `SNPtoAA.pl` is the one to run. The rest are helper scripts.

 📜 `/script/SNAtoAA.pl`

&nbsp;&nbsp;Master script. Run it to generate the plot.

📜 `/script/vcfToTsv_v3.pl`

&nbsp;&nbsp;Converts a human readable `vcf` to a `tsv`. 

📜 `/script/HGVStoBiomart.pl`

&nbsp;&nbsp;Converts mutations like 

>*XXXX_YYYYdelAATTAAGAGAAGCAACATCTCC>TCTC*

to variants separated by forward slash (default input of i-pv). 

Needs a single column, will verify based on mRNA and protein sequences and then convert. 

### 📜 `/script/invokeCircos.pl`

&nbsp;&nbsp;Invokes circos manually. Use this to invoke circos later or modify the datatracks created by the master script. It is akin to:

```perl
> perl path/to/circos -conf=path/to/circos-p/templates/circos_template.conf -outputdir=path/to/circos-p/Output
```


This script is not compatible when the main script is run via `--config` option, as someone can move the files out of `datatracks` through config.

## Recommendations

- If on windows, use strawberry perl.
- Make sure dependencies of circos is met.

## Legacy Recommendations

These recommendations are automatically taken care of when using I-PV `^2.0`

- Use circos version 0.67-7.
- If you are using perl 5.22 use the provided `circos-0.67-7_perl_5_22` circos distribution. If you are using perl 5.26, use the other. The only difference between these packages are the `SVG.pm` regex expressions.
- If on windows, versions of circos newer than 0.67-7 will give an error, replace the circos file in the *./bin folder* of circos with the same file coming from 0.67-7 version.
- If you use these newer versions of circos, a compulsory white background is added. So when your output from i-pv is generated, go to `./Output` folder and open the html file, search for a group with the id of `bg` and remove it. This should solve the white background issue.

## Notes

- Do not change the files in the `./template` folder. <br>
- You can watch the tutorial videos online at [**i-pv.org**](http://i-pv.org/)
- Are you looking for the Javascript codes? Go to the [**circos-p/templates**](./circos-p/templates) folder and look for `javascript.txt`.
- The javascript is encapsulated inside the html tag of which the svg will be embedded by the perl script.<br>
- `./circos-p/Output` folder might include examples from previous versions.