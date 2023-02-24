# PeneOS CDN / CI

## [Read the HTML readme file](https://cdn.pene.cc/readme.html)

This compiles PeneOS automatically and then hosts it at [cdn.pene.cc](https://cdn.pene.cc/)

## NGINX Setup Example

```nginx
server {
  listen 80;
  listen [::]:80;
  sever_name cdn.pene.cc;
  root /www/cdn;
  index index.html index.htm;

  location / {
    autoindex on;
    try_files $uri $uri/ =404;
  }
}
```
