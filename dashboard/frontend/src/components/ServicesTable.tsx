import React from 'react'

export default function ServicesTable({ services, selected, onSelect, onAction, onShowLogs }: any) {
  return (
    <div className="servicesTable">
      <div className="tableHeader">Services</div>
      <table>
        <thead>
          <tr><th>#</th><th>Name</th><th>Image</th><th>Status</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {services && services.map((s: any, idx: number) => (
            <tr key={s.Id || s.id} className={(s.Id||s.id)===selected? 'selected':''} onClick={() => onSelect(s.Id||s.id)}>
              <td>{idx+1}</td>
              <td>{(s.Names && s.Names[0]) || s.names || ''}</td>
              <td>{s.Image || s.image}</td>
              <td>{s.Status || s.status}</td>
              <td>
                <button onClick={(e)=>{ e.stopPropagation(); onAction(s.Id||s.id,'start')}}>Start</button>
                <button onClick={(e)=>{ e.stopPropagation(); onAction(s.Id||s.id,'stop')}}>Stop</button>
                <button onClick={(e)=>{ e.stopPropagation(); onShowLogs(s.Id||s.id)}}>Logs</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
