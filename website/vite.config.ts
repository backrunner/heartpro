import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { svedocs } from 'svedocs/vite';
import config from './svedocs.config.ts';
export default defineConfig({ plugins: [svedocs({ config, theme: { components: { Header: '$lib/SiteHeader.svelte', Footer: '$lib/SiteFooter.svelte' } } }), tailwindcss(), sveltekit()] });
