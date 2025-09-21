import React from 'react';
import { createRoot } from 'react-dom/client';
import App from '../src/App';
import '../styles/app.css';

const mountReactApp = () => {
  const container = document.getElementById('root');
  if (!container) return;

  const root = createRoot(container);
  root.render(<App />);
};

document.addEventListener('DOMContentLoaded', mountReactApp);
