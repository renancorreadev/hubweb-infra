server {
    server_name hubweb3.com www.hubweb3.com;

    location / {
        proxy_pass http://localhost:1000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/hubweb3.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/hubweb3.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot


}
server {
    if ($host = www.hubweb3.com) {
        return 301 https://$host:8443$request_uri;
    } # managed by Certbot


    if ($host = hubweb3.com) {
        return 301 https://$host:8443$request_uri;
    } # managed by Certbot


    listen 80;
    server_name hubweb3.com www.hubweb3.com;
    return 404; # managed by Certbot
}