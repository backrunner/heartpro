---
title: "Data and permissions"
description: "Control local records, Health access, symptoms and exported reports."
---

## Read access
HeartPro initially requests ECG, heart rate and HRV read access. Choose the types you want. The application cannot tell whether you denied a read permission: an empty result may mean that access is restricted or there are no records. You can still use synthetic examples.

## Optional write access
Writing is requested only when you choose to save supported symptoms from a note. HeartPro never writes synthetic examples, ECG classifications or its algorithm results to Health. Existing ECGs remain read-only. Editing local free text does not edit a symptom already written to Health.

## Revoke and clear
In Apple Health, open your profile and the list of apps with access, choose HeartPro and change permissions. Menu wording may vary by system version.

In HeartPro, choose **Settings → Clear HeartPro local data** and confirm. This clears local records, analysis, notes, sync checkpoints, waveform cache and temporary report files. It resets the local connection state. Reconnecting and syncing can import records again if Health permission remains granted. Original Health samples and reports saved or shared outside HeartPro are unaffected.

## Retention and backups
The protected app health-data directory is excluded from backups and CloudKit is disabled. HeartPro does not provide remote note backup. Export anything needed before clearing. Expired temporary reports are cleaned at the next launch after 24 hours, not by a guaranteed background timer. The [privacy policy](/privacy) explains website and support-email handling separately.
