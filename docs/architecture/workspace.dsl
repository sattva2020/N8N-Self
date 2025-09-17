workspace {
  model {
    user = person "User" "A user of the system"

    system = softwareSystem "N8N Self" "Self-hosted n8n + LightRAG dashboard" {
      webapp = container "Dashboard (Frontend)" "React + Vite" "Serves the SPA and static assets"
      backend = container "API (Backend)" "Fastify" "Business logic and API"
      db = container "Postgres" "PostgreSQL" "Primary data store"

      user -> webapp "Uses"
      webapp -> backend "Calls REST API"
      backend -> db "Reads/Writes data"
    }
  }

  views {
    systemContext system {
      include *
      autolayout lr
    }

    container system {
      include *
      autolayout lr
    }

    theme default
  }

  documentation {
    // Add architecture notes here when needed
  }
}
