import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import i18n from 'laravel-vue-i18n/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/js/app.js'],
            refresh: true,
        }),
        vue({
            template: {
                base: null,
                // Com includeAbsolute=false e tags={} desligamos toda a
                // transformacao de atributos src/href em templates Vue para
                // imports ESM. Atributos como <img src="/assets/x.png"> e
                // <source src="/storage/y.mp3"> ficam como URLs literais no
                // bundle e sao resolvidas pelo Laravel em runtime, sem que o
                // Rollup tente tratar PNG/WEBP/MP3 como modulo JavaScript.
                transformAssetUrls: {
                    includeAbsolute: false,
                    tags: {},
                },
            },
        }),
        i18n(),
    ],
    resolve: {
        alias: {

        }
    },
});
