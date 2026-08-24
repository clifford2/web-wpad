# Serve this content in a container
#
# Build with:
#   make build-release
# Run with:
#   make open-release
#   make stop-release

FROM docker.io/nginxinc/nginx-unprivileged:1.31.4-alpine3.24-slim
COPY --chmod=0644 examples/nginx-default.conf /etc/nginx/conf.d/default.conf
COPY --chmod=0644 dist/ /usr/share/nginx/html/
USER root
RUN echo 'Fix permissions' \
	&& find /usr/share/nginx/html -type d -exec chmod 0755 '{}' \;
USER $UID
