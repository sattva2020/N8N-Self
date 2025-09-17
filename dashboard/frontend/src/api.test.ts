vi.mock('axios');
import axios from 'axios';
import * as api from './api';

describe('api', () => {
  it('getInfo calls axios.get and returns data', async () => {
    (axios.get as any).mockResolvedValue({ data: { env: 'dev' } });
    const info = await api.getInfo();
    expect(info.env).toBe('dev');
  });

  it('getLogs returns logs', async () => {
    (axios.get as any).mockResolvedValue({ data: 'log1' });
    const logs = await api.getLogs('1', 100);
    expect(logs).toBe('log1');
  });
});
