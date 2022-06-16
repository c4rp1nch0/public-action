FROM node:16-alpine 

COPY entrypoint.sh  /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

