import React from 'react';

export default function DetailsPanel({ service }: any) {
  if (!service) return <div className="detailsPanel">Select a service</div>;
  return (
    <div className="detailsPanel">
      <h3>Details</h3>
      <div>
        <strong>ID:</strong> {service.Id || service.id}
      </div>
      <div>
        <strong>Names:</strong> {(service.Names || service.names || []).join(', ')}
      </div>
      <div>
        <strong>Image:</strong> {service.Image || service.image}
      </div>
      <div>
        <strong>Status:</strong> {service.Status || service.status}
      </div>
      <pre className="labels">
        {JSON.stringify(service.Labels || service.labels || {}, null, 2)}
      </pre>
    </div>
  );
}
