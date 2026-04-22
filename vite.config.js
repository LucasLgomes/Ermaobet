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
            // URLs absolutas do tipo /assets/* e /storage/* sao servidas pelo
            // Laravel em runtime. Marcamos como external para o Rollup deixar
            // a string como esta no bundle sem tentar resolver como modulo.
            external: (id) => /^\/(assets|storage|bonus|pgsoft|sounds|originals|livewire|build)\//.test(id),
        },
    },
});
