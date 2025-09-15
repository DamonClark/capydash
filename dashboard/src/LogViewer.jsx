import React from 'react';

function LogViewer({ events, onSelect }) {
  return (
    <div>
      <h2>Test Steps</h2>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {events.map((event) => (
          <li
            key={event.id}
            style={{
              padding: '0.5rem',
              margin: '0.25rem 0',
              border: '1px solid #eee',
              cursor: 'pointer',
              backgroundColor: event.status === 'failed' ? '#ffe5e5' : '#f5f5f5',
            }}
            onClick={() => onSelect(event)}
          >
            <strong>{event.step_name}</strong> - {event.status} <br />
            <small>{new Date(event.timestamp).toLocaleTimeString()}</small>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default LogViewer;
