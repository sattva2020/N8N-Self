import React, { useEffect, useState, useCallback } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import TopBar from './components/TopBar'
import ServicesTable from './components/ServicesTable'
import DetailsPanel from './components/DetailsPanel'
import LogsPane from './components/LogsPane'
import * as api from './api'

function DashboardApp() {
  const [info, setInfo] = useState<any>(null)
  const [services, setServices] = useState<any[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [showLogsFor, setShowLogsFor] = useState<string | null>(null)

  const load = useCallback(async () => {
    try {
      const [i, s] = await Promise.all([api.getInfo(), api.getServices()])
      setInfo(i)
      setServices(s)
    } catch (e) {
      console.error(e)
    }
  }, [])

  useEffect(() => {
    load()
    // SSE for events
    let evt: EventSource | null = null
    try {
      // Avoid creating real EventSource in unit tests / jsdom
      if (!(typeof process !== 'undefined' && process.env.NODE_ENV === 'test') && !(typeof window !== 'undefined' && (window as any).__TEST__)) {
        evt = new EventSource('/api/events')
        evt.onmessage = (ev) => {
        try {
          const data = JSON.parse(ev.data)
          // data is array of containers
          setServices((prev) => {
            // simple replace by id
            const byId = new Map(prev.map((p) => [p.Id || p.id, p]))
            for (const c of data) byId.set(c.Id || c.id, c)
            return Array.from(byId.values())
          })
        } catch (err) { console.error('sse parse', err) }
        }
      }
      evt.onerror = (err) => { console.warn('SSE err', err) }
    } catch (e) {
      console.warn('SSE not available', e)
    }
    return () => { if (evt) evt.close() }
  }, [load])

  const onAction = async (id: string, action: string) => {
    await api.postAction(id, action)
    // optimistic refresh
    setTimeout(load, 800)
  }

  return (
    <div className="appRoot">
      <TopBar info={info} />
      <div className="layout">
        <div className="main">
          <ServicesTable
            services={services}
            selected={selected}
            onSelect={setSelected}
            onAction={onAction}
            onShowLogs={setShowLogsFor}
          />
        </div>
        <aside className="side">
          <DetailsPanel service={services.find(s => (s.Id||s.id) === selected)} />
        </aside>
      </div>
      {showLogsFor && (
        <LogsPane id={showLogsFor} onClose={() => setShowLogsFor(null)} />
      )}
    </div>
  )
}

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <DashboardApp />
  </React.StrictMode>
)

export default DashboardApp
