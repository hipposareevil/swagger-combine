Table of Contents
=================
   * [Introduction](#introduction)
      * [caveats](#caveats)
   * [Repos used](#repos-used)
   * [Building image](#building-image)
   * [Usage](#usage)
      * [Running against locally hosted servers](#running-against-locally-hosted-servers)
      * [Running against docker environment](#running-against-docker-environment)
   * [References](#references)

# Introduction
It is difficult to combine multiple [swagger](http://swagger.io) outputs into a single format. This project is designed to help.

For instance, you have multiple REST endpoints defined in swagger that is aggregated through a [gateway-api](http://microservices.io/patterns/apigateway.html). You want to expose the combined REST interfaces as a single swagger definition. You can expose each swagger definition, but that's not how they're ultimately used. 

This project creates a [Docker](http://docker.com) image combines multiple [swagger](http://swagger.io) definitions into one. The resulting container can be run on the localhost or in a docker environment (via docker-compose for example).

This image will also live on [hub.docker.com/r/hipposareevil/swagger-combine/](https://hub.docker.com/r/hipposareevil/swagger-combine/)

## caveats
The input swagger files can be either *json* or *yaml*. *json* files are converted via [node](https://www.npmjs.com/package/json2yaml) into yaml.

When merging multiple definitions, when there is a collision of data the last one will win. So it will matter what order you pass files into this process.

In my project I am using swagger definitions from multiple dropwizard services and one spring boot. To make sure the host URL is ok, I pass in a secondary yaml file that override the *host* and *info* entries:
```
swagger: '2.0'
info: {description: Exciting stuff. , title: Super Web Service}
host: localhost:8080
```

# Repos used
This uses code from the following github repositories:

Repo | Purpose
--- | ---
[merge-yml](https://github.com/cobbzilla/merge-yml) | Java project to combine yaml files
[swagger-ui](https://github.com/swagger-api/swagger-ui) | Swagger-ui the serves the final result

# Building image
Clone this repository and then run:

```
> docker build -t swagger-combine .
```

# Usage
The program accepts either command line arguments or environment variable COMBINE_URLS (comma separated list).

To run against the swagger petstore:
```
> docker run -p 8080:8080 swagger-combine http://petstore.swagger.io/v2/swagger.yaml
```

Or as environment variable (useful for docker-compose):
```
> docker run -e COMBINE_URLS=http://petstore.swagger.io/v2/swagger.yaml,http://other.url/swagger.yaml  -p 8080:8080 swagger-combine
```

The commandline will accept multiple URLs (with yaml files):

```
> docker run -p 8080:8080 swagger-combine URL_1/swagger.yaml URL_2/swagger.yaml
```

## Running against locally hosted servers
Say you are running a local server on port 8765 with 2 endpoints and want to combine those:
* localhost:8080/foo/swagger.yaml
* localhost:8080/bar/myswagger.yml

First obtain your IP address:
```
on ubuntu> ip route get 8.8.8.8 | awk '{print $NF; exit}'
10.1.2.3
on mac> ip route get 8.8.8.8 | awk '{print $NF; exit}'
10.1.2.3
```

Then run docker image:
```
> docker run -p 8765:8080 swagger-combine 10.1.2.3:8080/foo/swagger.yaml 10.1.2.3:8080/bar/myswagger.yml
```

Open browser to [localhost:8765](http://localhost:8765/) and the combined yaml will be shown in the swagger-ui.

## Running against docker environment
Say you are running two micro-services (exposed on port 8080) behind a gateway-api and want to combine both REST endpoints. These are running in docker containers on the network *my_network*. 

Launch the swagger ui via:
```
> docker run -p 8765:8080 --network my_network swagger-combine serviceone:8080/swagger.yaml servicetwo:8080/swagger.yaml
```

Open browser to [localhost:8765](http://localhost:8765/) and the combined yaml will be shown in the swagger-ui.


# References

* [merge-yml](https://github.com/cobbzilla/merge-yml)
* [swagger-ui project](https://github.com/swagger-api/swagger-ui)
* [json2yaml](https://www.npmjs.com/package/json2yaml)
