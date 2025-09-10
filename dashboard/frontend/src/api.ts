import axios from 'axios'

axios.defaults.withCredentials = true

export async function getInfo() {
  const { data } = await axios.get('/api/info')
  return data
}

export async function getServices() {
  const { data } = await axios.get('/api/services')
  return data
}

export async function postAction(id: string, action: string) {
  const { data } = await axios.post(`/api/services/${id}/action`, { action })
  return data
}

export async function getLogs(id: string, tail = 200) {
  const { data } = await axios.get(`/api/services/${id}/logs?tail=${tail}`)
  return data
}
