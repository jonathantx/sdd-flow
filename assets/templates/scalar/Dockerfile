# Scalar — referência de API interativa servida como estático via nginx.
# O index.html carrega o openapi.yaml (montado em volume em runtime).
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY openapi.yaml /usr/share/nginx/html/openapi.yaml
EXPOSE 80
