import React from 'react'

export default function ServicesTable({ services = [], selected, onSelect, onAction, onShowLogs }: any) {
  return (
    <div className="services-table bg-white rounded shadow-sm overflow-hidden">
      <div className="px-4 py-3 border-b bg-gray-50 text-sm text-gray-700">Services</div>
      <table className="min-w-full text-sm">
        <thead className="bg-gray-100 text-gray-600">
          <tr>
            <th className="px-4 py-2 text-left">#</th>
            <th className="px-4 py-2 text-left">Name</th>
            <th className="px-4 py-2 text-left">Image</th>
            <th className="px-4 py-2 text-left">Status</th>
            <th className="px-4 py-2 text-left">Actions</th>
          </tr>
        </thead>
        <tbody>
          {services.map((s: any, idx: number) => {
            const id = s.Id || s.id
            const name = (s.Names && s.Names[0]) || s.names || s.name || ''
            const image = s.Image || s.image || ''
            const status = s.Status || s.status || 'unknown'
            return (
              <tr key={id} className={`${id === selected ? 'bg-gray-50' : ''} hover:bg-gray-50 cursor-pointer`} onClick={() => onSelect && onSelect(id)}>
                <td className="px-4 py-2">{idx + 1}</td>
                <td className="px-4 py-2">{name}</td>
                <td className="px-4 py-2">{image}</td>
                <td className="px-4 py-2"><span className={status === 'running' ? 'text-green-600' : 'text-red-600'}>{status}</span></td>
                <td className="px-4 py-2 space-x-2">
                  <button onClick={(e) => { e.stopPropagation(); onAction && onAction(id, 'start') }} className="px-2 py-1 bg-green-600 text-white rounded text-xs hover:bg-green-700">Start</button>
                  <button onClick={(e) => { e.stopPropagation(); onAction && onAction(id, 'stop') }} className="px-2 py-1 bg-yellow-600 text-white rounded text-xs hover:bg-yellow-700">Stop</button>
                  <button onClick={(e) => { e.stopPropagation(); onShowLogs && onShowLogs(id) }} className="px-2 py-1 bg-blue-600 text-white rounded text-xs hover:bg-blue-700">Logs</button>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

