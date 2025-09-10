import React from 'react'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import LogsPane from './LogsPane'
import * as api from '../api'

vi.mock('../api')

describe('LogsPane', () => {
  beforeEach(() => {
    ;(api.getLogs as any).mockResolvedValue('line1\nline2')
  })

  it('renders logs and supports tail/follow controls', async () => {
    const onClose = vi.fn()
    render(<LogsPane id="svc1" onClose={onClose} />)

    expect(screen.getByText(/Logs:/i)).toBeInTheDocument()

    await waitFor(() => expect(api.getLogs).toHaveBeenCalledWith('svc1', 200))
    expect(await screen.findByText(/line1/)).toBeInTheDocument()

    const tailInput = screen.getByLabelText(/tail/i) as HTMLInputElement
    fireEvent.change(tailInput, { target: { value: '50' } })
    await waitFor(() => expect(api.getLogs).toHaveBeenCalledWith('svc1', 50))

    const followCheckbox = screen.getByLabelText(/Follow/i) as HTMLInputElement
    // use act and fake timers to simulate follow polling
    await act(async () => {
      vi.useFakeTimers()
      fireEvent.click(followCheckbox)
      expect(followCheckbox.checked).toBe(true)
      // advance timers to let interval trigger
      vi.advanceTimersByTime(3100)
      await Promise.resolve()
      vi.useRealTimers()
    })

    fireEvent.click(screen.getByText(/Close/i))
    expect(onClose).toHaveBeenCalled()
  })
})
