-- Initial application schema (skeleton)
-- NOTE: n8n uses its own schema; здесь только примеры для прикладных таблиц.

-- Пример таблицы для сервис‑каталога (если потребуется в dashboard)
CREATE TABLE IF NOT EXISTS service_catalog (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  owner TEXT,
  url TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Индекс по owner для удобных выборок
CREATE INDEX IF NOT EXISTS idx_service_catalog_owner ON service_catalog(owner);

-- Таблица для Miro маппинга (если хотим вынести из n8n БД)
-- В n8n примере используется таблица miro_mapping; добавим с ON CONFLICT под UPSERT
CREATE TABLE IF NOT EXISTS miro_mapping (
  service_id TEXT PRIMARY KEY,
  widget_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
