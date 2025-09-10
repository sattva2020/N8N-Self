import React, { useEffect, useState } from 'react'
import axios from 'axios'

export default function TopBar({ info }: { info?: any }) {
  const [user, setUser] = useState<any>(null)
  useEffect(() => {
    let mounted = true
    axios.get('/oauth2/userinfo').then(r => { if (mounted) setUser(r.data) }).catch(()=>{})
    return ()=>{ mounted=false }
  }, [])

  const logout = async () => {
    try { await axios.post('/oauth2/sign_out'); window.location.href = '/'; } catch(e) { window.location.href = '/'; }
  }

  return (
    <header className="topbar">
      <div className="logo">Project Dashboard</div>
      <div className="spacer" />
      <div className="env">{info ? info.env : 'unknown'}</div>
      <div className="user">{user ? `${user.email} ▾` : 'User ▾'}
        <button onClick={logout} className="ml-2 px-2 py-1 text-sm bg-gray-100 rounded">Logout</button>
      </div>
    </header>
  )
}
