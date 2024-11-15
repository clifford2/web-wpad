FROM docker.io/nginxinc/nginx-unprivileged:1.27.2-alpine3.20
ARG UID=101
COPY --chmod=0644 nginx-default.conf /etc/nginx/conf.d/default.conf
COPY --chmod=0644 dist/ /usr/share/nginx/html/
USER root
RUN echo 'Fix permissions' \
  && find /usr/share/nginx/html -type d -exec chmod 0755 '{}' \; \
  && chown -R $UID:$UID /usr/share/nginx/html
USER $UID
