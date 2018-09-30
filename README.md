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
This project creates a [Docker](http://docker.com) image that when run as a container will combine multiple [swagger](http://swagger.io) definitions into one. 

It is difficult to combine multiple [swagger](http://swagger.io) outputs into a single format. This is designed to help.

For instance, you have multiple REST endpoints defined in swagger that is aggregated through a [gateway-api](http://microservices.io/patterns/apigateway.html). You want to expose the combined REST interfaces as a single swagger definition. You can expose each swagger definition, but that's not how they're ultimately used. 

This image will also live on [hub.docker.com/r/hipposareevil/swagger-combine/](https://hub.docker.com/r/hipposareevil/swagger-combine/)

## caveats
The input swagger files can be either *json* or *yaml*.  Any *json* files are converted via [json2yaml](https://www.npmjs.com/package/json2yaml) into yaml.

When merging multiple definitions, and there is a collision of data, the last one will win. It then will matter what order files are passed into the process.

The underlying *merge-yml* process will substitute environment variables into the resulting yaml file. For example, if the following is in a yaml file:
```
superkey: {{ENV_VARIABLE_FOO}}
```
and you have set *ENV_VARIABLE_FOO*, it will show up in the end yaml file.

## Personal example

In my project I am using swagger definitions from multiple dropwizard services and one spring boot. To make sure the host URL is what I want, I pass in a secondary yaml file that override the *host* and *info* entries:
```
swagger: '2.0'
info: {description: Exciting stuff. , title: Super Web Service}
host: {{DEPLOY_HOST_NAME}}:8080
```

Note the use of *DEPLOY_HOST_NAME*, which is mustache-style syntax, which I then set via environment variables.

# Repos used
This uses code from the following github repositories:

Repo | Purpose
--- | ---
[merge-yml](https://github.com/cobbzilla/merge-yml) | Java project to combine yaml files
[swagger-ui](https://github.com/swagger-api/swagger-ui) | Swagger-UI that serves the final result

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

The commandline will accept multiple URLs (with yaml files):

```
> docker run -p 8080:8080 swagger-combine URL_1/swagger.yaml URL_2/swagger.yaml
```

Or use environment variable (useful for docker-compose):
```
> docker run -e COMBINE_URLS=http://petstore.swagger.io/v2/swagger.yaml,http://other.url/swagger.yaml  -p 8080:8080 swagger-combine
```

Setting environment variable for use in one of the yaml files:
```
> docker run -e DEPLOY_HOST_NAME=myhost.com -e COMBINE_URLS=http://petstore.swagger.io/v2/swagger.yaml,http://other.url/swagger.yaml  -p 8080:8080 swagger-combine
```

## Running against locally hosted servers
You have two endpoints on a local server on port 8080 and wish to run the Swagger UI on port 8765.  You have the following two yaml endpoints:
* localhost:8080/foo/swagger.yaml
* localhost:8080/bar/myswagger.yml

First obtain your IP address:
```
on ubuntu> ip route get 8.8.8.8 | awk '{print $NF; exit}'
10.1.2.3
on mac> ip route get 8.8.8.8 | awk '{print $NF; exit}'
10.1.2.3
```

Then run container, exposing port 8765:
```
> docker run -p 8765:8080 swagger-combine 10.1.2.3:8080/foo/swagger.yaml 10.1.2.3:8080/bar/myswagger.yml
```

Open browser to [localhost:8765](http://localhost:8765/) and the combined yaml will be shown in the swagger-ui.

## Running against docker environment
Or there are two micro-services (each exposed on port 8080) behind a gateway-api and you want to combine both REST endpoints. They are running in docker containers on the network *my_network*. 

Launch the swagger ui via:
```
> docker run -p 8765:8080 --network my_network swagger-combine serviceone:8080/swagger.yaml servicetwo:8080/swagger.yaml
```

Open browser to [localhost:8765](http://localhost:8765/) and the combined yaml will be shown in the swagger-ui.


# References

* [merge-yml](https://github.com/cobbzilla/merge-yml)
* [swagger-ui project](https://github.com/swagger-api/swagger-ui)
* [json2yaml](https://www.npmjs.com/package/json2yaml)
