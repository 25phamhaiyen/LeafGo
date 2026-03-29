# Không cần build trong Docker, chỉ serve file đã build
FROM nginx:1.25-alpine AS final

RUN rm /etc/nginx/conf.d/default.conf

# Copy trực tiếp từ build/web trên máy thật
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN nginx -t

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]