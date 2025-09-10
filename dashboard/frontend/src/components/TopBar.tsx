import React, { useEffect, useState } from 'react'
import axios from 'axios'

export default function TopBar({ info }: { info?: any }) {
  const [user, setUser] = useState<any>(null)
  useEffect(() => {
    let mounted = true
    // Avoid real network calls during unit tests: tests can set global.__TEST__ = true
    if ((typeof process !== 'undefined' && process.env.NODE_ENV === 'test') || (typeof window !== 'undefined' && (window as any).__TEST__)) {
      return () => { mounted = false }
    }
    axios.get('/oauth2/userinfo').then(r => { if (mounted) setUser(r.data) }).catch(()=>{})
    return ()=>{ mounted=false }
  }, [])

  const logout = async () => {
    try { await axios.post('/oauth2/sign_out'); window.location.href = '/'; } catch(e) { window.location.href = '/'; }
  }

  return (
    <header className="topbar">
      <div className="logo text-lg font-semibold">Project Dashboard</div>
      <div className="flex-1" />
      <div className="env text-sm text-gray-600 mr-4">{info ? info.env : 'unknown'}</div>
      <div className="user flex items-center gap-2">
        <div className="text-sm text-gray-700">{user ? user.email : 'User'}</div>
        <button onClick={logout} className="px-2 py-1 text-sm bg-gray-100 rounded hover:bg-gray-200">Logout</button>
      </div>
    </header>
  )
}
