# Website design changes

The website uses neutral surfaces, system fonts and restrained coral accents. The svedocs and svedocs-cli dependencies were upgraded from 0.2.1 to 0.3.0.

## Landing and contrast

- Removed decorative orbit wrappers and the hero status-dot capsule.
- Moved the privacy note below the app preview so it does not obscure the screenshot.
- Increased secondary-text contrast in both themes. The dark primary button uses dark text on its brighter coral background.
- Kept the existing native app screenshots and their synthetic-data captions.

## Navigation and search

- The navigation header is 60px tall, with 44px minimum targets for its controls.
- Mobile search occupies its own 48px row. Language selection shows the full language name, and theme switching includes the translated action label.
- The mobile search dialog opens near the top, includes a search icon and limits result excerpts to three lines.
- Search dialogs outside the main content root receive the same dark-theme colors as the rest of the site.
- Framework search, localization, theme persistence, keyboard shortcuts and dialog focus restoration remain connected.

## Validation

Passed local checks: Svelte/TypeScript, strict bilingual content checks, production build, 8 support-intake tests and 9 browser tests. Browser coverage includes mobile theme changes, search results and focus restoration after closing search.

Visual review covered English and Simplified Chinese, light and dark themes, desktop and mobile layouts. Widths from 320px to 1440px were checked for horizontal overflow. Screenshots were generated from the production preview; temporary captures and build output remain ignored.

This review does not establish a complete accessibility audit or physical-device Safari/keyboard validation.
