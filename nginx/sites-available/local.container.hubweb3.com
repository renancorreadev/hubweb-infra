server {
    listen 80;
    listen [::]:80;
    server_name local.container.hubweb3.com;

    # Redireciona para HTTPS
    location / {
        return 301 https://$host:8443$request_uri;
    }
    
    # Para o desafio do Let's Encrypt (se necessário)
    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt; # Certifique-se de que este diretório exista
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name local.container.hubweb3.com;

    # SSL configuration (usando snakeoil para testes locais)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    # Outras configurações SSL (pode incluir as do snippets/snakeoil.conf se necessário)
    include snippets/snakeoil.conf;

    # Logs
    access_log /var/log/nginx/local.container.hubweb3.com-access.log;
    error_log /var/log/nginx/local.container.hubweb3.com-error.log;

    # Desativa o buffering
    proxy_buffering off;
    proxy_request_buffering off;
    
    # Configurações de proxy
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-Port $server_port;
    
    # Configurações de tempo limite
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    send_timeout 300s;
    
    # Desativa o buffering para WebSocket
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    
    # Configuração do proxy para o Portainer (ou outro serviço local que deseja testar)
    location / {
        proxy_pass http://127.0.0.1:9000; # Altere a porta 9000 se o Portainer estiver em outra porta
        
        # Configurações adicionais para o Portainer
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        
        # WebSocket
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Desativa o buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
} 