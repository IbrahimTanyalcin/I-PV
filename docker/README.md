# Run I-PV as a docker container

## Docker Hub

To get a list of published images:

[![Readme-Docker](https://img.shields.io/badge/ibowankenobi-ipv-skyblue
)](https://hub.docker.com/r/ibowankenobi/i-pv)

## Quickstart

Assuming you have a working docker installation, you cloned the I-PV repo and have an already built I-PV image (or the one pulled from docker hub) with name `image_name` and tag `image_tag`:

Pick a folder where you will have your config file, for example `/home/xyz`, and make sure it is writable by others:

```shell
chmod -R 755 ~/xyz
```
Copy `i-pv/circos-p/Input/nfkb1` as `testInput`:

```shell
cp -R ./i-pv/circos-p/Input/nfkb1 ~/xyz/testInput
```

Create a config file named `myConfig.json`, copy inside the `xyz` folder and paste the following contents into it:

```json
{
	"path": "  config  ",
	"proteinFileName": "testInput/fasta.txt",
	"mrnaFileName": "testInput/mRNA.txt",
	"name": "NFKB",
	"domains": [
		{
			"start": 50,
			"end": 126,
			"name": "domain_X",
			"color": "vdred"
		}
	],
	"circos": {
		"output": "./testOutput/output",
		"mkdir": 1,
		"cleanup": 1
	},
	"datatracks": {
		"cleanup": 1,
		"mkdir": 1,
		"move": "./testOutput/datatracks"
	}
}
```
Lastly, run:

```shell
docker run -it --mount type=bind,source=/home/xyz,target=/app/mount image_name:image_tag -i myConfig.json
```

You should have your outputs inside `xyz/testOutput/output` with a single file called `NFKB.html`.


## Option 1: Build the image yourself

Make sure you have docker engine installed.

Once you clone the I-PV repository, `cd` to `./docker` folder:

```shell
docker build -t image_name:tag_name .  
```
This will build an image using the Dockerfile inside that location.

To remove the image, use 
```shell
docker rmi image_id
```

You can see the image id using `docker image list`. If you cannot remove the image, it means there were stopped containers using that image. Find them using `docker ps -a` and then remove them using `docker rm`. You can also use `docker system prune` for that purpose.

## Option 2: Pull the image from Docker Hub

```shell
docker pull ibowankenobi/i-pv
```

## Running the container
Assuming you have your input file in `/path/to/folder`:

```shell
docker run -it --mount type=bind,source=/path/to/folder,target=/app/mount image_name:tag_name
```

The `image_name` is a combination of `DockerID` and repo name, for IPV, it should be `ibowankenobi/i-pv`. If you did not build the image but pulled it instead, then:

```shell
docker run -it --mount type=bind,source=/path/to/folder,target=/app/mount ibowankenobi/i-pv:1.0.0
```

Replace `ibowankenobi/i-pv:1.0.0` with the version you want or `ibowankenobi/i-pv:latest`.

In Linux system beware that path's starting with `/` are absolute. In Windows the above command would look something like:

```shell
docker run -it --mount type=bind,source=D:\Tests\mountTest,target=/app/mount ibowankenobi/i-pv:1.0.0
```

Inside the container the processes do NOT run as root but as the user 'IPV'. For that reason, on Linux systems make sure the mounted drive has write access permissions, something like `755`.

The default mount path is assumed to be `/app/mount` inside the container. You can override it by setting an environment variable called `MOUNT_PATH`:

```shell
docker run -it -e MOUNT_PATH='/app/anotherLocation' --mount type=bind,source=/path/to/folder,target=/app/anotherLocation ibowankenobi/i-pv:1.0.0
```

Or pass `--mount` argument:

```shell
docker run -it --mount type=bind,source=/path/to/folder,target=/app/anotherLocation ibowankenobi/i-pv:1.0.0 --mount /app/anotherLocation
```

## List of arguments

-i, --input

Specifies the input file. Use file name and extension, like 

`... -i myInput.json`

If this option is not provided, the container assumes that there is an input file called `config.json` inside the mounted folder.

-d, --daemon

Runs it in daemon mode, this functionality is not implemented yet. Instead you will get a warning message that repeats every few seconds. Either use `docker stop` with the container id or do `Ctrl + c`

-m, --mount

If you want to change the location of the mounted folder inside the container, along with using `docker run -it --mount ...`, you also need to tell the `Node` process where is the mounted folders location. You can either do this by setting environment variables or the `-m` argument. `--mount` or `-m` has higher order of precedence compared to `MOUNT_PATH` environment variable. If both are not set, then the `Node` process assumes the mounted folder location is `/app/mount`. For example:

```shell
docker run -it -e MOUNT_PATH='/app/anotherLocation1' --mount type=bind,source=/path/to/folder,target=/app/anotherLocation2 ibowankenobi/i-pv:1.0.0 -i yourInput.json -m /app/anotherLocation2
```

Above command would disregard the `MOUNT_PATH` env variable and correctly report the location of the mounted folder as `/app/anotherLocation2` because `-m` overrides docker's `-e`.

Usually it is NOT necessary to use either `-e MOUNT_PATH=...` or I-PV's `-m` as long as you do not change the `target=...` part of the docker's `--mount`.


