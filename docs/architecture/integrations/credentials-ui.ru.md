# Создание креденшелов в n8n (Postgres + Miro) — руководство по UI

Это руководство покроково показывает, как создать креденшелы Postgres и Miro в интерфейсе n8n. Замените плейсхолдеры скриншотов своими захватами (или используйте скриншоты в репо, если они есть).

## Обзор

- Файл: `docs/architecture/integrations/credentials-ui.ru.md`
- Скриншоты: положите изображения в `docs/architecture/integrations/images/` с именами, указанными ниже.

---

## 1) Откройте раздел Credentials

1. Войдите в ваш экземпляр n8n.
2. В левой панели выберите **Personal** → **Credentials** (или в верхнем меню Credentials).

![credentials-list](images/01-credentials-list.png)

## 2) Добавьте креденшел Postgres

1. Нажмите **Add** / **New Credential** (или **Add first credential**).
2. В открывшемся диалоге выберите тип **Postgres**.

![add-credential](images/02-add-credential.png)

1. Заполните поля соединения:

	- Host — например `localhost` или адрес вашей БД
	- Database — например `postgres` или `myproject_db`
	- User — пользователь БД (например `n8n_user`)
	- Password — пароль пользователя
	- Port — обычно `5432`
	- Maximum Number of Connections — начните с `5-20`
	- Ignore SSL Issues — не включайте в продакшен

![postgres-form](images/03-postgres-form.png)

2. (Опционально) Во вкладке **Details** добавьте описание, например `Project DB for Miro mapping`.
3. Нажмите **Save**.

### Специфично для этого проекта (docker-compose)

В вашем `stack/docker-compose.yml` Postgres для n8n описан как сервис `n8n-postgres`. Если n8n запущен в том же `docker-compose`, используйте следующие значения при создании креденшела:

- Host: `n8n-postgres`
- Port: `5432`
- Database: `n8n`
- User: `n8n`
- Password: содержимое Docker secret `secrets/n8n_db_password` (см. ниже)

Примеры команд PowerShell, чтобы прочитать секрет (выполните на хосте, где находится репозиторий):

```powershell
# из корня репозитория
Get-Content -Raw '..\secrets\n8n_db_password'

# или полный путь
Get-Content -Raw 'E:\AI\N8N\secrets\n8n_db_password'
```

Если n8n запущен в том же compose — указывайте `n8n-postgres` как Host; `localhost` НЕ будет работать внутри контейнера (localhost внутри контейнера указывает на сам контейнер).

Если n8n запущен вне Docker (на хосте), а Postgres в контейнере — используйте `host.docker.internal` или реальный IP хоста и убедитесь, что контейнер разрешает внешние подключения.

## 3) Добавьте креденшел Miro (HTTP Header Auth)

1. Нажмите **Add** → выберите **HTTP Header Auth** (или Generic API key в зависимости от версии UI).
2. В полях заголовка укажите:

- Name: `Authorization`
- Value: `Bearer <YOUR_MIRO_TOKEN>`

![miro-credential](images/04-miro-credential.png)

1. При необходимости добавьте описание и сохраните.

---

## 3.1) (Альтернатива) Создание Miro OAuth2 credentials (рекомендуется для команд)

На скриншоте сверху видно, что в диалоге добавления креденшелов доступен пункт "Miro OAuth2 API" — это встроённый тип OAuth2 в n8n. Ниже инструкция как создать OAuth‑app в Miro и настроить Redirect URL.

1. Создание OAuth‑app в Miro

- Откройте страницу разработчика Miro: [Miro Developer settings](
    https://miro.com/app/settings/developer/) и создайте новое приложение (Create new app).

- Заполните поля:

	- Name: `n8n Miro Integration` (любой понятный ярлык)
	- Description: `Integration for syncing architecture board`

- Redirect URI (callback): укажите адрес n8n, который будет принимать ответ OAuth2. Для локальной разработки под Docker Compose используйте:

```text
http://localhost:5678/rest/oauth2-credential/callback
```

Для удалённого деплоя замените host на ваш публичный адрес, например:

```text
https://n8n.example.com/rest/oauth2-credential/callback
```

- Scopes: отметьте как минимум `boards:read` и `boards:write`. При необходимости добавьте scopes для работы с карточками/фреймами (cards, frames и т.д.).

- Сохраните приложение и скопируйте Client ID и Client Secret.

2. Настройка в n8n

- В n8n откройте **Credentials** → **Add** и найдите **Miro OAuth2 API** (как на скриншоте вверху).
- Вставьте Client ID и Client Secret.
- В поле Redirect/Callback URL укажите тот же URL, который вы зарегистрировали в Miro (см. выше).
- Сохраните и нажмите кнопку Authorize — n8n откроет окно для OAuth-потока и попросит войти в Miro.

3. Проверка

- После успешного OAuth в n8n в credentials появится активный credential, готовый к использованию в HTTP Request узлах.

![miro-oauth2](images/05-miro-oauth2.png)

---

## 4) Пример workflow: Create / Update с использованeм "Miro OAuth2 API"

Ниже минимальный пример на n8n (логика для демонстрации):

- Start -> Function (makePayload) -> HTTP Request (Create) -> Function (extractId) -> HTTP Request (Update)

1) Function (makePayload) — формирует тело для создания виджета (sticky note):

```javascript
// Пример содержимого Function node
return [{
	json: {
		body: {
			type: 'sticky_note',
			text: 'Тестовый стикер от n8n (OAuth)',
			x: 0,
			y: 0,
			style: { fillColor: 'light_blue' }
		}
	}
}];
```

2) HTTP Request (Create)

```text
Method: POST
URL: https://api.miro.com/v2/boards/BOARD_ID/items
Authentication: используйте credential 'Miro OAuth2 API'
Body Content Type: JSON
Body: {{$json.body}}
```

3) Function (extractId)

```javascript
// Извлекаем id созданного элемента из ответа Create
const res = $node["HTTP Request"].json;
const itemId = res.id || (res.data && res.data.id);
return [{ json: { itemId } }];
```

4) HTTP Request (Update)

```text
Method: PATCH
URL: https://api.miro.com/v2/boards/BOARD_ID/items/{{$json.itemId}}
Authentication: используйте credential 'Miro OAuth2 API'
Body Content Type: JSON
Body: { "text": "Обновлённый текст от n8n (OAuth)" }
```

Запустите workflow вручную и проверьте, что созданный элемент обновляется. Если возникает 401 или проблемы с правами — перепроверьте scopes и Redirect URL в настройках OAuth‑app.

---

После внесения правок отмечу задачу как Completed в todo.

---

## 4.1) Полный walkthrough «Build your first app» (install flow)

Ниже шаг‑за‑шаг как в Miro Dev docs: создание приложения, установка на команду/доску и webhook flow.

1) Создайте новое приложение в Miro Developer Dashboard (Name, Description).

2) Укажите Redirect URL (см. раздел ниже про Traefik). Для локальной разработки обычно используется `http://localhost:5678/rest/oauth2-credential/callback`, но в production URL должен быть публичным без порта при использовании Traefik (подробнее ниже).

3) В разделе Scopes отметьте: `boards:read`, `boards:write`. Если будете использовать webhooks — добавьте scopes для webhook управления.

4) Webhook / installation flow (упрощённо):

 - Пользователь устанавливает приложение на команду или доску (Install). Miro отправляет установочный payload вашему redirect / install endpoint.

 - Ваш сервер подтверждает установку и сохраняет installation data (team id, access token / refresh token).

 - Если вы используете server-side OAuth, вы обменяете code на access token по стандартному OAuth flow.

Пример установки webhook (из документации Miro): отправьте запрос POST на `https://api.miro.com/v2/webhooks` с Authorization: Bearer <ACCESS_TOKEN> и телом с `target` (URL вашего сервера) и `event`.

## 4.2) Пример локального redirect-handler (мини‑скрипт)

Ниже минимальный Node.js express‑сервер, который принимает callback и печатает code (для локального теста). Не использовать в продакшене без валидации и безопасности.

```javascript
// simple-oauth-callback.js
const express = require('express');
const app = express();
const port = process.env.PORT || 5678;

app.get('/rest/oauth2-credential/callback', (req, res) => {
	const { code, state } = req.query;
	console.log('OAuth callback received', { code, state });
	// Здесь обменяйте code на access token согласно Miro OAuth guide
	res.send('Callback received — check server logs');
});

app.listen(port, () => console.log(`Listening on ${port}`));
```

Команда для запуска (PowerShell):

```powershell
node simple-oauth-callback.js
```

После запуска откройте URL установки приложения в Miro; в процессе авторизации Miro вернёт code на ваш callback URL.

## 4.3) Почему `https://n8n.sattva-ai.top:5678/rest/oauth2-credential/callback` — неправильный

Из `stack/docker-compose.yml` видно, что Traefik пробрасывает публичный домен `n8n.${DOMAIN_NAME}` на внутренний контейнер n8n. Traefik слушает 443 и 80 снаружи и делает маршрутизацию по Host. Поэтому в Redirect URL **не указывайте порт** и используйте тот хост, который Traefik обслуживает.

Правильно (пример):

```text
https://n8n.sattva-ai.top/rest/oauth2-credential/callback
```

Пояснение:
- Traefik принимает запрос на 443 и пробрасывает внутрь контейнера на порт 5678. Внешний URL не должен содержать внутренний порт. Указание `:5678` приведёт к тому, что Miro попытается обратиться по адресу с портом, который, возможно, не открыт наружу (и вернёт ошибку).

Если вы не можете использовать публичный домен, альтернативы:

- Использовать `http://localhost:5678/rest/oauth2-credential/callback` для тестирования локально (и включить redirect в приложении Miro).
- Сделать проброс порта на шлюзе (gateway) — это возможно, но менее корректно с точки зрения TLS и Traefik; лучше настроить Traefik так, чтобы публичный домен маршрутизировал к контейнеру.

Если хотите, могу автоматически заменить пример URL в `credentials-ui.ru.md` на правильный без порта и добавить инструкцию по проверке Traefik (как увидеть, на каком хосте слушает и какие роуты настроены).

---

После правок отмечу задачу как Completed в todo.

## 5) Утилиты для проверки и обмена токеном

Добавлены два вспомогательных скрипта в `docs/architecture/integrations/scripts/`:

- `check-traefik-routes.ps1` — PowerShell скрипт для вывода docker labels и быстрой проверки доступности callback URL (запускайте на хосте с docker). Пример использования:

```powershell
# В корне репозитория
cd docs/architecture/integrations/scripts
$env:DOMAIN_NAME = 'sattva-ai.top'
.\check-traefik-routes.ps1
```

- `miro-oauth-exchange.js` — Node.js скрипт для обмена полученного `code` на `access_token` по Miro OAuth (использует API `https://api.miro.com/v1/oauth/token`). Пример использования:

```powershell
node miro-oauth-exchange.js <CLIENT_ID> <CLIENT_SECRET> <CODE> <REDIRECT_URI>
```

Примечание по безопасности: не коммитьте `client_secret`, `access_token` или `refresh_token` в репозиторий. Храните их в защищённых хранилищах или в n8n credentials.

## 6) Redirect URI и проверка callback

Важно: когда вы используете Traefik (или другой reverse-proxy), публичный Redirect URI должен указывать на внешний хост/домен, под которым доступен n8n, и НЕ должен содержать внутренний порт контейнера. Пример правильного URI:

```text
https://n8n.sattva-ai.top/rest/oauth2-credential/callback
```

Неправильный (и часто встречающаяся причина ошибки "invalid redirect_uri") — указание внутреннего порта контейнера, например:

```text
https://n8n.sattva-ai.top:5678/rest/oauth2-credential/callback  # НЕ ИСПОЛЬЗОВАТЬ
```

Пример быстрой проверки доступности callback (HEAD запрос):

```bash
curl -I https://n8n.sattva-ai.top/rest/oauth2-credential/callback
```

Анализ вашего вывода curl (пример):

```
HTTP/1.1 200 OK
Content-Length: 813
Content-Type: text/html; charset=utf-8
Date: Fri, 12 Sep 2025 20:05:35 GMT
Strict-Transport-Security: max-age=15552000
...
```

Вывод показывает HTTP 200 — это значит, что Traefik корректно маршрутизирует запрос на n8n и конечная точка доступна по публичному URL. Поэтому причина ошибки авторизации в Miro была именно в несоответствии зарегистрированного Redirect URI (в Miro) и того, что отправлял ваш клиент — уберите порт :5678 в настройках приложения Miro и повторите flow.

Если после этого проблема останется — пришлите точную строку Redirect URI, зарегистрированную в Miro, и вывод `curl -vI https://n8n.sattva-ai.top/rest/oauth2-credential/callback` (полный verbose), я помогу дальше.

## 4) Использование креденшелов в workflow

- Откройте workflow `Miro Sync - n8n` и откройте узел Postgres.
- Выберите созданный Postgres‑креденшел в выпадающем списке credentials узла.
- В HTTP Request узлах для Miro выберите HTTP Header credential или используйте выражение `Bearer {{$credentials["Miro Credential"].value}}` для вставки токена.

## 5) Тестирование

- В узле Postgres нажмите **Execute Node** чтобы проверить соединение с БД.
- В HTTP Request узле (CreateMiro) нажмите **Execute Node** чтобы протестировать вызов Miro (используйте безопасный тестовый payload).

## Имена скриншотов

Положите скриншоты в `docs/architecture/integrations/images/` с такими именами:

- `01-credentials-list.png` — страница списка креденшелов
- `02-add-credential.png` — диалог добавления нового креденшела
- `03-postgres-form.png` — заполненная форма Postgres
- `04-miro-credential.png` — заполнение Miro header auth

---

## Примечания по безопасности

- НЕ коммитьте изображения или файлы, содержащие реальные токены или пароли. Перед коммитом замазывайте/редактируйте чувствительные поля.
- Для продакшена используйте хранение секретов в UI креденшелов n8n или секретный менеджер, а не в репозитории.

---

Если хотите, я могу:

- Вставить ваши присланные скриншоты в руководство (вы уже загрузили один), или
- Самостоятельно поднять локальный n8n и сделать демонстрационные скриншоты.

Что предпочитаете?
