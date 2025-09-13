## Тестирование CreateMiro/UpdateMiro узлов с бесплатным аккаунтом Miro

Этот документ описывает минимальные шаги для тестирования нод CreateMiro/UpdateMiro в `n8n`, используя бесплатный аккаунт Miro и Personal Access Token (PAT).

Коротко:
- Зарегистрируйте бесплатный аккаунт на miro.com (если ещё нет).
- Создайте Personal Access Token в настройках разработчика или используйте OAuth app для более сложных сценариев.
- Импортируйте или настройте в `n8n` HTTP-credential для Miro с этим токеном.
- Протестируйте создание и обновление виджета (стикера) на вашей доске.

Важно: бесплатные аккаунты Miro поддерживают Personal Access Token и ограничены по API-лимитам и по количеству команд/досок. PAT даёт доступ в пределах прав вашего пользователя; не используйте PAT в публичных репозиториях.

### 1) Подготовка аккаунта и получение Personal Access Token (PAT)

1. Зайдите на https://miro.com и зарегистрируйтесь (Free plan).
2. Перейдите в профиль → Settings → Developer settings (или откройте https://miro.com/app/settings/developer/).
3. В разделе "Personal access tokens" нажмите "Create token".
4. Дайте токену имя и отметьте необходимые scope: для простых Create/Update нужно как минимум `boards:write` и `boards:read`.
5. Скопируйте сгенерированный токен сразу — Miro показывает его только один раз.

Совет по безопасности: храните PAT в `n8n` Credentials (тип HTTP Header / OAuth2) или в переменных окружения, не в публичных файлах.

### 2) Быстрый curl-проверочный запрос (проверка токена и доски)

1. Найдите ID доски: откройте желаемую доску в браузере, в URL после `/app/board/` находится ID вида `xxxxxxxxxxxxxx`.

2. Выполните запрос, чтобы получить информацию о доске (замените `YOUR_TOKEN` и `BOARD_ID`):

```powershell
# PowerShell (pwsh) пример
$headers = @{"Authorization" = "Bearer YOUR_TOKEN"}
Invoke-RestMethod -Method Get -Uri "https://api.miro.com/v2/boards/BOARD_ID" -Headers $headers
```

Или curl (если доступен):

```powershell
curl -H "Authorization: Bearer YOUR_TOKEN" "https://api.miro.com/v2/boards/BOARD_ID"
```

Ожидаемый результат: JSON с метаданными доски (id, name, description). Если вернулся 401 — проверьте токен и scopes.

### 3) Тест Create (создать стикер) — пример HTTP-запрос

Пример тела для создания стикера (sticky note):

```powershell
$body = @{
  type = 'sticky_note'
  text = 'Тестовый стикер от n8n'
  x = 0
  y = 0
  style = @{ fillColor = 'light_yellow' }
} | ConvertTo-Json -Depth 4

Invoke-RestMethod -Method Post -Uri "https://api.miro.com/v2/boards/BOARD_ID/items" -Headers $headers -Body $body -ContentType 'application/json'
```

Ответ: JSON, содержащий id созданного виджета (например `"id": "abc123"`). Сохраните этот id — он нужен для Update.

### 4) Тест Update (обновить стикер)

Используйте `id` виджета из ответа Create и выполните PATCH: (замените `ITEM_ID`)

```powershell
$updateBody = @{ text = 'Обновлённый текст от n8n' } | ConvertTo-Json
Invoke-RestMethod -Method Patch -Uri "https://api.miro.com/v2/boards/BOARD_ID/items/ITEM_ID" -Headers $headers -Body $updateBody -ContentType 'application/json'
```

Ожидаемый результат: JSON с обновлённым объектом.

### 5) Как протестировать в n8n

1. В `n8n` создайте новые Credentials:
   - Тип: HTTP Header
   - Имя: `Miro Personal Token`
   - Заголовок: `Authorization: Bearer <ВАШ_TOKEN>`

2. Импортируйте или создайте workflow с узлами примерно следующей структуры:
   - Start -> Function (формирует payload) -> HTTP Request (Create) -> Function (извлекает id) -> HTTP Request (Update)

HTTP Request (Create) настройки:
 - Method: POST
 - URL: https://api.miro.com/v2/boards/BOARD_ID/items
 - Authentication: выберите `Miro Personal Token` (или укажите заголовок вручную)
 - Body: Raw JSON (payload как выше)

HTTP Request (Update) настройки:
 - Method: PATCH
 - URL: https://api.miro.com/v2/boards/BOARD_ID/items/{{$node["Function"].json["itemId"]}}
 - Body: Raw JSON (например { "text": "Обновлённый текст" })

3. Запустите workflow вручную и проверьте, что Create возвращает `id`, а Update обновляет тот же элемент.

Совет: используйте `n8n` логирование (console) или Function node для печати результатов и отладки.

### 6) Ограничения бесплатного аккаунта и рекомендации


### 7) Быстрые проверки при ошибках


Если хотите, могу автоматически добавить этот файл в Table of Contents и ссылку из `docs/architecture/integrations/README.md`, а также подставить пример workflow `miro-n8n.json` в виде шага "Импортировать пример".

Файл с инструкцией создан автоматически. Если нужно — добавлю английскую версию и CI-проверку, которая бы валидировала базовые HTTP-запросы (требует токен в GitHub Secrets).

### Полезные ссылки

