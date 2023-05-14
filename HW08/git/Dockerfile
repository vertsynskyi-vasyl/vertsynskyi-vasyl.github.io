FROM nginx

COPY test.conf /etc/nginx/conf.d/default.conf

RUN printf "testuser:$(openssl passwd -apr1 test1234)\n" > /etc/nginx/.htpasswd

