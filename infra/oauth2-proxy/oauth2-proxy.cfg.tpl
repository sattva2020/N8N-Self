# oauth2-proxy config template
provider = "oidc"
issuer_url = "http://keycloak:8080/realms/dashboard"
client_id = "dashboard-client"
client_secret = "{{OAUTH2_PROXY_CLIENT_SECRET}}"
redirect_url = "https://dashboard.${DOMAIN_NAME}/oauth2/callback"
cookie_secret = "{{OAUTH2_PROXY_COOKIE_SECRET}}"
upstreams = ["http://dashboard-backend:3000/"]
http_address = "0.0.0.0:4180"
email_domains = ["*"]
