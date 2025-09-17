import React, { useEffect, useState } from 'react';
import * as api from '../api';

export default function LogsPane({ id, onClose }: any) {
  const [logs, setLogs] = useState<string>('');
  const [tail, setTail] = useState<number>(200);
  const [follow, setFollow] = useState<boolean>(false);

  const load = async () => {
  const data = await api.getLogs(id, tail);
  setLogs(data);
  };

  useEffect(() => {
    load();
    let t: any = null;
    if (follow) t = setInterval(load, 3000);
    return () => {
      if (t) clearInterval(t);
    };
  }, [id, tail, follow]);

  return (
    <div className="logsPane">
      <div className="logsHeader">
        <div>Logs: {id}</div>
        <div>
          <label>
            tail{' '}
            <input type="number" value={tail} onChange={(e) => setTail(Number(e.target.value))} />
          </label>
          <label>
            <input type="checkbox" checked={follow} onChange={(e) => setFollow(e.target.checked)} />{' '}
            Follow
          </label>
          <button onClick={onClose}>Close</button>
        </div>
      </div>
      <pre className="logsContent">{logs}</pre>
    </div>
  );
}
