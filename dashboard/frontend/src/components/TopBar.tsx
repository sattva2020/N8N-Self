import React from 'react'

export default function TopBar({ info }: { info?: any }) {
  return (
    <header className="topbar">
      <div className="logo">Project Dashboard</div>
      <div className="spacer" />
      <div className="env">{info ? info.env : 'unknown'}</div>
      <div className="user">User ▾</div>
    </header>
  )
}
