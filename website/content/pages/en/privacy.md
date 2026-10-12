---
title: "Privacy policy"
description: "How HeartPro handles health records, notes, reports, website visits and support requests."
---

**Effective date: 11 October 2026.** HeartPro is operated under the Alkinum brand. Privacy and support: [support form](/support).

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
The website has no analytics, advertising, hosted AI, health upload form or external font service. Search runs in your browser using a downloaded index. A theme preference may be saved locally in your browser. The website is hosted and delivered through Cloudflare. Cloudflare processes IP addresses, browser and request information to deliver pages, protect the service and operate its infrastructure. HeartPro has no separately configured visitor-log storage or profiling. Cloudflare service logs are retained under its applicable service policies.

The [support form](/support) sends your email address, selected topic, subject, message, preferred reply language, and any app version, iOS/iPadOS version or device model you choose to enter to our OnFire support system, hosted on Cloudflare. Authorized support staff use this information to handle your request. The form has no file upload and does not automatically access Health records, device diagnostics or app data. Do not include health records, ECG PDFs, health screenshots or Apple ID credentials. Entering an email does not grant access to previous tickets; customer session credentials remain on the server.

Only the support page loads Cloudflare Turnstile, which processes network and browser information to prevent abuse. The server also uses your IP address to limit submission attempts. Support requests and follow-up correspondence remain in OnFire for as long as needed to handle your request and meet applicable legal obligations; closing a ticket does not automatically delete it. Choose **Privacy request** on the support page to request access, correction or deletion. Clearing HeartPro's local data does not delete support tickets.

If you choose to email support, your email provider and our Cloudflare services process your address, message and any attachments. We use this correspondence only to handle support and privacy requests. Do not send health data unnecessarily. Correspondence is retained for as long as needed to handle your request, resolve the issue and meet applicable legal obligations. You may request deletion through the support address, except for information needed for an ongoing dispute or required by law. The app does not automatically collect or send email.

Cloudflare uses global infrastructure; website requests and support correspondence may be processed outside your country or region. See [Cloudflare’s privacy policy](https://www.cloudflare.com/privacypolicy/) and [customer data processing addendum](https://www.cloudflare.com/cloudflare-customer-dpa/) for its processing, retention and cross-border safeguards.

## Requests, rights and updates
Revoke Health consent through Apple Health and delete local data in HeartPro. We cannot remotely retrieve or erase app data that stays only on your device. For support correspondence or privacy questions, contact the address above. Health access and optional writes depend on your authorization. Support correspondence is used to handle your request; website request information is used to deliver and protect the service. Under applicable law, you may request access, correction, deletion or restriction of relevant processing, withdraw consent and complain to your competent local data protection authority. We handle requests under applicable law; withdrawal does not affect earlier lawful processing. Material changes will be reflected here with an effective date.

## TestFlight testing
When installed through TestFlight, Apple processes tester, installation, usage and crash information under its TestFlight terms and privacy disclosures. Feedback and screenshots you choose to submit may also be available to the developer. This is separate from HeartPro itself not uploading health records. Avoid including unnecessary personal health information in feedback or attachments. See [Apple’s TestFlight privacy information](https://www.apple.com/legal/privacy/data/en/test-flight/).
