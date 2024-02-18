import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import dts from 'vite-plugin-dts';

const path = fileURLToPath(import.meta.url);
const root = resolve(dirname(path));

export default defineConfig({
  root,
  plugins: [dts()],
  build: {
    copyPublicDir: false,
    lib: {
      name: 'Browser',
      entry: resolve(root, 'lib', 'index.ts'),
      formats: ['umd'],
      fileName: (format) => `browser.${format}.js`,
    },
    rollupOptions: {
      external: [],
      output: {
        globals: {},
        extend: true,
      },
    },
  },
});
