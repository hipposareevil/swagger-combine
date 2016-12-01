FROM mhart/alpine-node:7.2

# Exposed 8080 to other containers
EXPOSE 8080

# packages for swagger-ui
RUN apk add --update nginx openssl curl

# setup for this version of nginx
RUN mkdir -p /run/nginx/
ENV NGINX_ROOT=/var/lib/nginx/html

##########################
# grab the swagger-ui
# Inspired by https://hub.docker.com/r/schickling/swagger-ui/
ENV SWAGGER_VERSION=2.2.8
ENV SWAGGER_FOLDER=swagger-ui-$SWAGGER_VERSION

RUN wget -qO- https://github.com/swagger-api/swagger-ui/archive/v$SWAGGER_VERSION.tar.gz | tar xvz
RUN cp -r $SWAGGER_FOLDER/dist .
# Change the default swagger file to be 'swagger.yaml'
# This will be expected in the $NGINX_ROOT directory,
# which will be created via the run.sh script
RUN  sed -i.bak s#http://petstore.swagger.io/v2/swagger.json#swagger.yaml# dist/index.html

# update nginx
RUN cp $SWAGGER_FOLDER/nginx.conf /etc/nginx/
RUN cp -r dist/* $NGINX_ROOT

# clean up downloaded folder
RUN rm -rf $SWAGGER_FOLDER dist

##########################
# grab the swagger-yaml files
# https://github.com/idlerun/swagger-yaml

# make directories for swagger-yaml
RUN mkdir -p /src
RUN mkdir -p /target

RUN wget -q https://raw.githubusercontent.com/idlerun/swagger-yaml/master/generate.js
RUN wget -q https://raw.githubusercontent.com/idlerun/swagger-yaml/master/package.json
RUN npm install

COPY waitforit.sh /
COPY run.sh /

ENTRYPOINT ["/run.sh"]
