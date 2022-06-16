FROM c4rp1nch0/security-tools-eslint:latest

COPY entrypoint.sh  /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

