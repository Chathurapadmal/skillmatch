# Project Structure

## App Code

- `lib/main.dart` - app bootstrap and platform setup

## Applicant Area

- `lib/pages/applicant/` - applicant-facing screens and flows
- `lib/pages/applicant/home/` - applicant landing and dashboard screens
- `lib/pages/applicant/jobs/` - applicant job browsing screens
- `lib/pages/applicant/profile/` - applicant profile screens
- `lib/pages/applicant/settings/` - settings, policy, and support screens
- `lib/pages/applicant/advanced/` - roadmap, credential, and skill tools

## Company Area

- `lib/pages/company/` - company-facing dashboard and management screens

## Shared App Flow

- `lib/pages/auth/` - sign-in and 2FA flow
- `lib/pages/` - root navigation and shell screens
- `lib/admin/` - admin dashboard

## Shared Layers

- `lib/services/` - app services and integrations
- `lib/services/ai/` - AI helpers backed by the Node backend
- `lib/shared/` - shared screens and overlays
- `lib/widgets/` - reusable widgets
- `lib/widgets/policy/` - policy-related UI cards
- `lib/models/` - data models
- `lib/theme/` - theme setup

## Backend

- `backend/` - Node/Express chatbot and job API

## Cleanup Performed

- Moved the browse-jobs screen into `lib/pages/applicant/jobs/`
- Removed Firebase AI usage from the app and kept AI calls behind the backend API
- Moved the terms-of-service card into `lib/widgets/policy/`
- Renamed the terms card widget to `TermsOfServiceCard`
- Removed the old misnamed source files that duplicated those paths
- Removed the empty placeholder asset file from `assets/images/`
