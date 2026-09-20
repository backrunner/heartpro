---
title: "Privacy policy"
description: "How HeartPro handles health records, notes, reports, website visits and support email."
robots: "noindex, follow"
---

**Publication draft · reviewed 20 September 2026.** The legal operator identity, hosting and email providers, their retention settings and the effective date must be confirmed before this policy is published as final or used for App Store submission. Contact: [support@heartpro.alkinum.com](mailto:support@heartpro.alkinum.com).

## Scope
This policy covers the HeartPro iOS/iPadOS app (`com.alkinum.heartpro`), this product website and voluntary support correspondence. The app and website handle data differently as explained below.

## Health data stays on your device
With your permission, HeartPro reads ECG records and waveforms, heart rate and heart rate variability (SDNN) from Apple Health to display records, summaries and trends and perform local analysis. Record metadata can include dates, duration, source-device information and Apple's source classification. These records, derived measurements and your notes are stored and processed locally; HeartPro does not upload them to us or an analysis service.

HeartPro has no account, advertising, tracking SDK, third-party analytics or remote AI service. We do not sell health data or use it for advertising, marketing, profiling or data brokerage. Synthetic examples are generated locally and are never written to Health.

## Your choices and Health permissions
You choose which Health read permissions to grant, and can revoke them at any time in Apple Health's app access settings. Revoking access does not erase copies already imported. Clear those in HeartPro Settings.

If you explicitly select the option to save symptoms to Health, the app requests permission for the supported symptoms you selected. It writes those symptoms, severity and times as separate entries with HeartPro as the source. Free-text notes stay local. Original ECGs and their notes are never modified. Manage already written symptom records directly in Apple Health; deleting a local note does not delete its Health entry.

## Local storage and retention
Local health records and notes remain until you clear them or delete the app. Deleting the app, rather than offloading it, removes its local container. A deleted source ECG is removed from the local ECG index at the next successful incremental sync; its separate local notes can remain until you clear or delete them.

The app applies iOS file protection to its health-data directory, excludes it from device backups and disables CloudKit storage. HeartPro does not sync health data to iCloud. Apple's own Health synchronization is controlled by Apple and your device settings, separately from HeartPro. The app obscures its content when it becomes inactive.

Regenerable waveform cache files may be evicted to limit storage. Temporary PDF copies older than 24 hours are removed on the next app launch. **Settings → Clear HeartPro local data** deletes local records, derived analyses, notes, sync state, waveform files and temporary PDF reports. It does not delete original Apple Health data, independent symptoms saved to Health, or copies you shared elsewhere. Local preferences such as whether you have seen the guide may remain.

## Sharing is your choice
Reports are created locally. The system share sheet sends a PDF only to the destination you choose. That destination may be another app, a cloud service or a recipient; its own terms and protections apply. HeartPro cannot recall or delete shared copies. Review the recipient and the contents before sharing.

## Website and support correspondence
The website has no analytics, advertising, hosted AI, health upload form or external font service. Search runs in your browser using a downloaded index. A theme preference may be saved locally in your browser. Ordinary requests disclose an IP address and browser/request information to the selected hosting/CDN provider. The provider, log retention and processing locations must be specified before publication.

If you choose to email support, your email provider and our chosen mailbox provider process your address, message and any attachments. We use this correspondence to answer your request. Do not send health data unnecessarily. The provider, processing locations and retention/deletion schedule for correspondence must be finalized before publication; no automatic email collection occurs in the app.

## Requests, rights and updates
Revoke Health consent through Apple Health and delete local data in HeartPro. We cannot remotely retrieve or erase app data that stays only on your device. For support correspondence or privacy questions, contact the address above, including requests for access, correction or deletion where applicable. Statutory rights, lawful bases, operator details, international-transfer safeguards and complaint contacts will be specified for the operator and launch regions before publication. Material changes will be reflected in this policy and its effective date.
