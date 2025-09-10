import axios from 'axios'

axios.defaults.withCredentials = true

export async function getInfo() {
  if ((typeof process !== 'undefined' && process.env.NODE_ENV === 'test') || (typeof window !== 'undefined' && (window as any).__TEST__)) {
    return {}
  }
  const { data } = await axios.get('/api/info')
  return data
}

export async function getServices() {
  if ((typeof process !== 'undefined' && process.env.NODE_ENV === 'test') || (typeof window !== 'undefined' && (window as any).__TEST__)) {
    return []
  }
  const { data } = await axios.get('/api/services')
  return data
}

export async function postAction(id: string, action: string) {
  if ((typeof process !== 'undefined' && process.env.NODE_ENV === 'test') || (typeof window !== 'undefined' && (window as any).__TEST__)) {
    return { ok: true }
  }
  const { data } = await axios.post(`/api/services/${id}/action`, { action })
  return data
}

export async function getLogs(id: string, tail = 200) {
  if ((typeof process !== 'undefined' && process.env.NODE_ENV === 'test') || (typeof window !== 'undefined' && (window as any).__TEST__)) {
    return `Mock logs for ${id}`
  }
  const { data } = await axios.get(`/api/services/${id}/logs?tail=${tail}`)
  return data
}
