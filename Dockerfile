FROM maven:3.3.9-jdk-8-alpine 

# Exposed 8080 to other containers
EXPOSE 8080

# packages for swagger-ui
RUN apk add --update nginx openssl curl bash

# setup for this version of nginx
RUN mkdir -p /run/nginx/
ENV NGINX_ROOT=/var/lib/nginx/html

# make directories used by the yaml merging
RUN mkdir -p /src /target


##########################
# grab the swagger-ui
# Inspired by https://hub.docker.com/r/schickling/swagger-ui/
ENV SWAGGER_VERSION=2.2.8
ENV SWAGGER_UI_FOLDER=swagger-ui-$SWAGGER_VERSION

RUN wget -qO- https://github.com/swagger-api/swagger-ui/archive/v$SWAGGER_VERSION.tar.gz | tar xvz
RUN cp -r $SWAGGER_UI_FOLDER/dist .
# Change the default swagger file to be 'swagger.yaml'
# This will be expected in the $NGINX_ROOT directory,
# which will be created via the run.sh script
RUN  sed -i.bak s#http://petstore.swagger.io/v2/swagger.json#swagger.yaml# dist/index.html

# update nginx
RUN cp $SWAGGER_UI_FOLDER/nginx.conf /etc/nginx/
RUN cp -r dist/* $NGINX_ROOT

# clean up downloaded folder
RUN rm -rf $SWAGGER_UI_FOLDER dist


#########################
# grab the merge-yaml java project
RUN wget https://github.com/cobbzilla/merge-yml/archive/master.zip
RUN unzip master.zip
RUN mvn -f merge-yml-master/pom.xml -P uberjar package

# clean up 
RUN rm -rf master.zip

########################
# copy in our scripts
COPY waitforit.sh /
COPY run.sh /

ENTRYPOINT ["/run.sh"]


