# Проверка Traefik маршрутов и docker labels
# Запускайте на хосте с docker

Write-Host "Список контейнеров и их labels (grep по 'traefik.http.routers')"

# Получить имена контейнеров
$containers = docker ps --format '{{.Names}}'
foreach ($c in $containers) {
    Write-Host "\n--- $c ---"
    docker inspect $c --format '{{json .Config.Labels}}' | ConvertFrom-Json | Where-Object { $_.psobject.properties.name -match 'traefik\.http' } | ForEach-Object { $_ }
}

Write-Host "\nПроверка доступности маршрута для n8n (HEAD):"
try {
    $url = "https://n8n.$env:DOMAIN_NAME/rest/oauth2-credential/callback"
    Write-Host "Запрашиваю: $url"
    curl -I $url
} catch {
    Write-Error "Ошибка при проверке URL: $_"
}
