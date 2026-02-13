# Usamos Nginx ligero
FROM nginx:alpine

# Copiamos nuestra configuración personalizada
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiamos la carpeta con los sitios
COPY services /usr/share/nginx/html
