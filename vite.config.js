import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import i18n from 'laravel-vue-i18n/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        vue({
            template: {
                base: null,
                includeAbsolute: false
            }
        }),
        i18n(),
    ],
    resolve: {
        alias: {

        }
    },
    build: {
        rollupOptions: {
            // Assets servidos pelo Laravel em /public/storage/* e /assets/*
            // sao URLs estaticas, nao modulos. Marcar como external para o
            // Rollup manter a string como esta no bundle.
            external: (id) => /^\/(public\/storage|assets|bonus|pgsoft|sounds|originals|livewire)\//.test(id),
        },
    },
});
