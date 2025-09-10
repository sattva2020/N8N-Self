import { render, screen } from '@testing-library/react'
import TopBar from './TopBar'

test('renders TopBar with env', () => {
  render(<TopBar info={{ env: 'production' }} />)
  expect(screen.getByText(/Project Dashboard/)).toBeInTheDocument()
  expect(screen.getByText('production')).toBeInTheDocument()
})
