import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // The Pharo service listens on 8080. Proxying in dev means the browser only
    // ever talks to one origin, so there is no CORS configuration to keep in
    // sync between environments — in production nginx does the same thing.
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
});
