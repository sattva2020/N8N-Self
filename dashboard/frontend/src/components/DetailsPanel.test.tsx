import React from 'react';
import { render, screen } from '@testing-library/react';
import DetailsPanel from './DetailsPanel';

describe('DetailsPanel', () => {
  it('shows placeholder when no service', () => {
    render(<DetailsPanel service={null} />);
    expect(screen.getByText(/Select a service/i)).toBeInTheDocument();
  });

  it('renders service details', () => {
    const svc = {
      id: '1',
      names: ['svc'],
      image: 'img:latest',
      status: 'running',
      labels: { a: 'b' },
    };
    render(<DetailsPanel service={svc} />);
    expect(screen.getByText(/Details/i)).toBeInTheDocument();
    expect(screen.getByText(/img:latest/i)).toBeInTheDocument();
    expect(screen.getByText(/running/i)).toBeInTheDocument();
  });

  it('handles empty labels and missing fields gracefully', () => {
    const svc = { id: '2' };
    render(<DetailsPanel service={svc} />);
    expect(screen.getByText(/Details/i)).toBeInTheDocument();
    expect(screen.getByText(/ID:/i)).toBeInTheDocument();
    expect(screen.getByText(/Names:/i)).toBeInTheDocument();
  });
});
