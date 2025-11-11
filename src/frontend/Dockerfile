FROM nginx:alpine

WORKDIR /app

# Copy frontend files
COPY index.html style.css script.js /usr/share/nginx/html/

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]