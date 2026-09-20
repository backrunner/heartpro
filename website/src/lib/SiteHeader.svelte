<script lang="ts">
  import { Navbar } from 'svedocs/theme';
  import type { SvedocsHeaderProps } from 'svedocs/theme/types';

  let { onCloseMobileMenu = () => {}, ...navbar }: SvedocsHeaderProps = $props();
  let scrollY = $state(0);

  function closeMenu() {
    onCloseMobileMenu();
    document.querySelector<HTMLButtonElement>('.hp-header .sd-menu-button')?.focus();
  }
</script>

<svelte:window bind:scrollY />

{#if navbar.mobileMenuOpen}
  <button class="hp-nav-scrim" aria-label={navbar.context.t('nav.mobile.close')} tabindex="-1" onclick={closeMenu}></button>
{/if}
<div class="hp-header" class:hp-header-scrolled={scrollY > 24}>
  <Navbar {...navbar} />
</div>
