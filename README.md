# Skinia (WIP — no image analysis backend yet)

Skinia is an iOS prototype for documenting skin lesions and preparing cases for future automated assessment. The current build runs locally and does not send images to a remote analysis service yet.

## At a Glance
- **Status:** work in progress / prototype
- **What works today:** local photo and case-review flows, analysis list/detail screens, mocked results for previews/tests, and MVVM-C app structure
- **Not implemented yet:** a production image-analysis backend, real clinical inference, or end-to-end remote submission

## 30-Second Quickstart
```bash
git clone https://github.com/ThalesMMS/Skinia.git
cd Skinia
open Skinia.xcodeproj
```
Then build and run the `Skinia` scheme in Xcode.

## Current Capabilities
- Analysis list that surfaces locally stored photos prepared for evaluation.
- Detailed analysis view displaying mock inference results for previews and tests.
- Accessibility coverage that includes VoiceOver labels, Dynamic Type, and focus order checks.
- Loading and empty states integrated into the SwiftUI navigation flow.
- Coordinator-driven navigation that mirrors the planned production routing without networking.

## Near-Term Priorities
- Camera capture experience optimized for dermatology scenarios.
- Integration layer to connect with the future image analysis backend.
- Privacy controls and user preferences for managing protected health information.

## Technical Architecture
### MVVM-C Pattern
- Models: SwiftData entities representing lesion photos, analysis results, and metadata.
- Views: SwiftUI screens and reusable components built for clinical review contexts.
- ViewModels: Observable objects encapsulating presentation logic and local state.
- Coordinators: Flow controllers responsible for navigation and dependency wiring.

### Platform Stack
- iOS 18.5+ with SwiftUI and SwiftData.
- Dependency injection through protocol-first service abstractions.
- Mock services and preview data to enable development without backend connectivity.

## Project Structure
```
Skinia/
├── Models/            # SwiftData entities and domain models
├── ViewModels/        # Core and camera view models
├── Coordinators/      # Navigation flows
├── Services/          # Repositories, API shims, and mocks
├── Utilities/         # Helpers and shared infrastructure
├── Assets.xcassets    # Design system and imagery
├── PreviewSupport/    # Sample data for SwiftUI previews
├── SkiniaTests/       # Unit test suites
└── SkiniaUITests/     # UI automation suites
```

## Analysis States
- `pending` – Waiting for user confirmation before upload.
- `uploading` – Preparing payload for remote submission (mocked locally today).
- `analyzing` – Processing in progress.
- `completed` – Analysis available for review.
- `failed` – Local validation or processing error.

## Risk Levels
- `low` – Minimal concern, informational follow-up advised.
- `moderate` – Requires clinician attention within standard timelines.
- `high` – Suggests expedited examination.
- `urgent` – Immediate clinical escalation recommended.

## Development Workflow
### Prerequisites
- Xcode 15.0 or newer
- iOS 18.5 SDK
- Swift 5.9 toolchain

### Setup
```bash
git clone https://github.com/ThalesMMS/Skinia.git
cd Skinia
open Skinia.xcodeproj
```

### Build and Test
```bash
xcodebuild -project Skinia.xcodeproj -scheme Skinia build
xcodebuild test -project Skinia.xcodeproj -scheme Skinia
```

## Clinical Use Disclaimer
Skinia is an auxiliary tool intended to support dermatology professionals. Diagnostic decisions must be made by qualified clinicians, and the application does not replace specialized medical consultation.

## Contributing
- Maintain the MVVM-C boundaries across coordinators, view models, and models.
- Prefer protocol-oriented dependency injection to keep previews and tests isolated.
- Extend the existing test suites in `SkiniaTests/` and `SkiniaUITests/` whenever adding business logic or UI flows.

## Maintainer
- Thales Matheus Mendonca Santos

## Authors
- Antonio Soares Couto Neto
- Arthur Oliveira Santos
- Fernanda Rodrigues Dias Mariano
- João Lucas Curi
- Luis Phillip Lemos Martins
- Thales Matheus Mendonça Santos

## License
This project is available under the [MIT](LICENSE) license.
