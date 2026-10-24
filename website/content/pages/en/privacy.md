---
title: "Privacy policy"
description: "How HeartPro handles health records, notes, reports, website visits and support requests."
---

**Effective date: 24 October 2026.** HeartPro is operated under the Alkinum brand. Read-only help: [support page](/support).

## Scope
This policy covers the HeartPro iOS/iPadOS app (`com.alkinum.heartpro`), this product website and its read-only help pages. The app and website handle data differently as explained below.

## App data is not collected
HeartPro does not collect your health records, notes or analysis results. They are processed and stored only on your device and are not automatically uploaded to developer or third-party servers. There are no accounts, ads, tracking or third-party analytics SDKs.

Only your explicit actions share a report with your chosen destination through the system share sheet or save selected symptoms to Apple Health. HeartPro does not sync health data through iCloud; Apple Health's own synchronization is controlled by system settings. Website delivery and Apple's TestFlight services have the separate disclosures below. This statement does not mean that no information is ever transmitted by your device.

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

## Website delivery
The website has no analytics, advertising, hosted AI, external font service or health-data upload feature. Search runs in your browser using a downloaded index. A theme preference may be saved locally in your browser. Cloudflare hosts and delivers the site and necessarily processes IP addresses and browser/request information to deliver pages and protect its infrastructure. We do not maintain a visitor database, user profiles or a separately configured visitor-log store. Worker observability is disabled. These controls do not mean Cloudflare never processes network data.

Cloudflare uses global infrastructure. Its processing and applicable rights are described in [Cloudflare's privacy policy](https://www.cloudflare.com/privacypolicy/) and [customer data processing addendum](https://www.cloudflare.com/cloudflare-customer-dpa/).

## Read-only support, no personal submissions
The [support page](/support) provides static troubleshooting guidance only. It has no contact form, email submission, attachments, account or ticket system. No Turnstile widget or support-provider script loads. We do not ask you to submit any personal information and do not create or manage new support records through this website.

The former support endpoint returns a disabled response. The Worker does not read, parse, log, store or forward its request body, identify a customer or contact a ticket provider. Infrastructure may still receive network requests as described above. Please do not attempt to send names, email addresses, identifiers, messages, health records, screenshots or files.

Disabling intake prevents new support collection; it does not itself erase any correspondence previously sent through former channels. This policy does not claim that historical records have been deleted.

## Local controls and updates
Revoke Health consent through Apple Health and delete local data in HeartPro. We cannot remotely retrieve or erase app data that stays only on your device. Health access and optional writes depend on your authorization. Website request information is processed for page delivery and protection as described above, not used to build support tickets or user profiles. Applicable legal rights remain unaffected. Material changes will be reflected here with an effective date.

## TestFlight testing
When installed through TestFlight, Apple processes tester, installation, usage and crash information under its TestFlight terms and privacy disclosures. Feedback and screenshots you choose to submit may also be available to the developer. This is separate from HeartPro itself not uploading health records. Avoid including unnecessary personal health information in feedback or attachments. See [Apple’s TestFlight privacy information](https://www.apple.com/legal/privacy/data/en/test-flight/).
