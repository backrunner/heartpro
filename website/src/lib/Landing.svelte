<script lang="ts">
  import type { SvedocsThemeContext } from 'svedocs/theme/types';
  import { resolveLocalizedHref } from 'svedocs/theme/headless';
  export let context: SvedocsThemeContext;
  let selected = 'waveform';
  const views = ['history', 'waveform', 'trends'];
  $: locale = context.localeCode === 'zh' ? 'zh-Hans' : 'en';
  $: href = (path: string) => resolveLocalizedHref(path, context);
</script>

<div class="hp-landing">
  <section class="hp-hero">
    <div class="hp-intro">
      <h1>{context.t('hero.title')}<br /><span>{context.t('hero.second')}</span></h1>
      <p class="hp-lead">{context.t('hero.body')}</p>
      <div class="hp-actions">
        <a class="hp-button" href={href('/docs')}>{context.t('hero.action')} <span aria-hidden="true">↗</span></a>
        <a class="hp-text-link" href={href('/release')}>{context.t('hero.release')} <span aria-hidden="true">→</span></a>
      </div>
      <p class="hp-meta">{context.t('hero.meta')}</p>
    </div>
    <div class="hp-preview">
      <div class="hp-preview-stage">
        <div class="hp-device">
          <img src={`/screenshots/${locale}-${selected}.webp`} width="1320" height="2868" alt={context.t(`preview.alt.${selected}`)} fetchpriority="high" />
        </div>
        <div class="hp-preview-tag">
          <span class="hp-lock-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24">
              <rect x="5" y="10" width="14" height="11" rx="3"/>
              <path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>
            </svg>
          </span>
          <span>{context.t('hero.private')}</span>
        </div>
      </div>
      <div class="hp-selector" role="group" aria-label={context.t('preview.label')}>
        {#each views as view}<button aria-pressed={selected === view} onclick={() => selected = view}>{context.t(`preview.${view}`)}</button>{/each}
      </div>
      <p class="hp-caption">{context.t('preview.caption')}</p>
    </div>
  </section>
  <section class="hp-flow" id="features">
    <p class="hp-eyebrow">{context.t('flow.kicker')}</p>
    <h2>{context.t('flow.title')}</h2>
    <div class="hp-features">
      {#each ['01', '02', '03'] as step}
        <div class="hp-feature">
          <div class="hp-feature-top">
            <span class="hp-feature-icon" aria-hidden="true"><svg viewBox="0 0 24 24">
              {#if step === '01'}<rect x="3" y="5" width="18" height="16" rx="4"/><path d="M7 3v4m10-4v4M3 11h18m-13 5h2m4 0h2"/>
              {:else if step === '02'}<path d="M2 12h5l3-8 4 16 3-8h5"/>
              {:else}<path d="M14 4H7a4 4 0 0 0-4 4v9a4 4 0 0 0 4 4h10a4 4 0 0 0 4-4v-6M9 15l1-4 8-8 3 3-8 8-4 1Z"/>{/if}
            </svg></span>
            <span class="hp-number">{step}</span>
          </div>
          <h3>{context.t(`flow.${step}.title`)}</h3><p>{context.t(`flow.${step}.body`)}</p>
        </div>
      {/each}
    </div>
  </section>
  <section class="hp-privacy">
    <div class="hp-privacy-copy">
      <p class="hp-eyebrow">{context.t('privacy.kicker')}</p>
      <h2>{context.t('privacy.title')}<br />{context.t('privacy.second')}</h2>
      <p>{context.t('privacy.body')}</p>
      <a class="hp-text-link" href={href('/privacy')}>{context.t('privacy.link')} <span aria-hidden="true">→</span></a>
    </div>
    <div class="hp-imprint">
      <img src="/app-icon.png" alt="" width="1024" height="1024" loading="lazy" />
      <p>{context.t('hero.records')}</p>
    </div>
  </section>
  <section class="hp-limits"><h2>{context.t('limits.title')}</h2><p>{context.t('limits.body')}</p><a class="hp-text-link" href={href('/docs/methods')}>{context.t('limits.link')} <span aria-hidden="true">→</span></a></section>
  <section class="hp-support"><div><h2>{context.t('support.title')}</h2><p>{context.t('support.body')}</p></div><a class="hp-button hp-secondary" href={href('/support')}>{context.t('support.action')} <span aria-hidden="true">↗</span></a></section>
</div>
