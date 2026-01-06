# Serve this content in a container
#
# Build with:
#   podman build -t web-wpad:$(cat .version) .
# Run with:
#   podman run --rm -d --name web-wpad -p 8080:8080 localhost/web-wpad:$(cat .version)
#   xdg-open http://0.0.0.0:8080/

FROM docker.io/nginxinc/nginx-unprivileged:1.29.3-alpine3.22-slim
ARG UID=101
COPY --chmod=0644 nginx-default.conf /etc/nginx/conf.d/default.conf
COPY --chmod=0644 dist/ /usr/share/nginx/html/
USER root
RUN echo 'Fix permissions' \
  && find /usr/share/nginx/html -type d -exec chmod 0755 '{}' \; \
  && chown -R $UID:$UID /usr/share/nginx/html
USER $UID
