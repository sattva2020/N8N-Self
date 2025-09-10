import { render, screen } from '@testing-library/react'
import ServicesTable from './ServicesTable'

test('renders table with services', () => {
  const services = [{ Id: '1', Names: ['/svc1'], Image: 'img', Status: 'Up' }]
  render(<ServicesTable services={services} />)
  expect(screen.getByText('/svc1')).toBeInTheDocument()
})
