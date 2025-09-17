workspace "FLCS Architecture" "C4 views for Food Label & Calorie Scan" {

    model {
        person user "Пользователь" "Сканирует этикетки и ведёт дневник"

        softwareSystem flcs "FLCS (Mobile + API)" "Скан состава + дневник калорий" {
            container mobile "Мобильное приложение (RN/Expo)" "React Native, Expo" "UI, камера, офлайн OCR, локальный кеш"
            container api "Edge API" "Serverless (Vercel/Cloudflare/Supabase)" "Парсинг ингредиентов, прокси к OFF, аутентификация"
            container db  "База данных" "Postgres (Supabase)" "foods, entries, ingredients, …"
            container queue "Очередь задач (опц.)" "Worker/Queue" "фоновая нормализация, кеширование"
        }

        softwareSystem off "Open Food Facts" "Публичное API штрих‑кодов"
        softwareSystem fdc "USDA FDC" "Каталог продуктов (без штрих‑кода)"
        softwareSystem openrouter "OpenRouter AI" "LLM-прокси для классификации ингредиентов"

        user -> mobile "Сканирует, просматривает, добавляет записи"
        mobile -> api "REST/HTTPS запросы"
        api -> db "CRUD, кеш и журналирование"
        api -> off "GET /product/{barcode}"
        api -> fdc "Поиск общих блюд (опц.)"
        api -> openrouter "POST /chat (strict JSON)"
        api -> queue "Постановка фона (опц.)"
    }

    views {
        systemContext flcs "c1-context" {
            include *
            autolayout lr
        }

        container flcs "c2-containers" {
            include *
            autolayout lr
        }

        component api "c3-api-components" {
            component rest "REST Layer" "Endpoints v1 (parse-ingredients, off-proxy, foods-search, diary)"
            component normalizer "Normalizers" "Очистка текста, сопоставление E‑кодов/аллергенов"
            component cache "Cache" "Кеш продуктов/ответов (Redis/pg)"
            component ai "AI Proxy" "Интеграция с OpenRouter (response_format=json_object)"
            component auth "Auth" "Сессии/ключи/API-токены"
            api -> rest "экспонирует"
            rest -> normalizer "использует"
            rest -> ai "вызывает"
            rest -> cache "читает/пишет"
            rest -> auth "проверяет"
            rest -> db "читает/пишет"
            autolayout lr
        }

        styles {
            element "Software System" { background #0ea5e9 color #ffffff }
            element "Container" { background #22c55e color #ffffff }
            element "Component" { background #a78bfa color #ffffff }
            element "Person" { background #f59e0b color #ffffff }
            relationship { routing Orthogonal }
        }
    }
}
