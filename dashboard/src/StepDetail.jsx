import React from 'react';

function StepDetail({ step }) {
  if (!step) return <div>Select a step to see details</div>;

  return (
    <div>
      <h2>Step Details</h2>
      <p><strong>{step.step_name}</strong></p>
      <p>Status: {step.status}</p>
      <p>Time: {new Date(step.timestamp).toLocaleTimeString()}</p>

      {(step.screenshot_url || step.data_url) && (
        <div style={{ marginTop: '1rem' }}>
          <h4>Screenshot:</h4>
          <img
            src={step.data_url || `file://${process.cwd()}/${step.screenshot_url}`}
            alt="Step Screenshot"
            style={{ maxWidth: '100%', border: '1px solid #ccc' }}
          />
        </div>
      )}

      {step.dom_snapshot && (
        <div style={{ marginTop: '1rem' }}>
          <h4>DOM Snapshot:</h4>
          <pre style={{ maxHeight: '300px', overflow: 'auto', background: '#f0f0f0', padding: '0.5rem' }}>
            {step.dom_snapshot}
          </pre>
        </div>
      )}
    </div>
  );
}

export default StepDetail;
