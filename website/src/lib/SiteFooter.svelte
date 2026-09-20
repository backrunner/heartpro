<script lang="ts">
  import type { SvedocsThemeContext } from 'svedocs/theme/types';
  import { resolveLocalizedHref } from 'svedocs/theme/headless';
  export let context: SvedocsThemeContext;
  $: footer = context.config.theme.footer;
</script>
{#if footer !== false}
  <footer class="hp-footer" data-theme-component="footer">
    <a class="hp-footer-brand" href={resolveLocalizedHref('/', context)}><img src="/app-icon.png" width="32" height="32" alt=""/><span>{context.t('footer.text', { site: 'HeartPro' })}</span></a>
    <nav aria-label={context.t('nav.footer')}>
      {#each footer.links as link}<a href={resolveLocalizedHref(link.href, context)}>{link.labelKey ? context.t(link.labelKey) : link.label}</a>{/each}
    </nav>
  </footer>
{/if}
