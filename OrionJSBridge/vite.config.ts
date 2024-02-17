import typescript from '@rollup/plugin-typescript';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import dts from 'vite-plugin-dts';

const path = fileURLToPath(import.meta.url);
const root = resolve(dirname(path));

export default defineConfig({
  root,
  plugins: [
    dts({ include: ['lib'] }),
    typescript({
      include: ['lib/**/*.ts'],
      exclude: ['node_modules', 'dist', 'vite.config.ts', 'globals.d.ts'],
      tsconfig: './tsconfig.json',
    }),
  ],
  build: {
    copyPublicDir: false,
    lib: {
      name: 'Browser',
      entry: resolve(root, 'lib', 'index.ts'),
      formats: ['es', 'cjs', 'umd'],
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
