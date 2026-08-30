<div align="center">

# 🍊 OranGo

### Sorting oranges by hand is slow and subjective. OranGo makes it fast, consistent, and visible in real time.

![Swift](https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0D1117?style=flat-square&logo=apple&logoColor=white)
![Vapor](https://img.shields.io/badge/Vapor-0D1117?style=flat-square&logo=swift&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/status-in%20progress-yellow?style=flat-square)

</div>

---

## 🧡 Why OranGo

Picture a produce warehouse where every crate of oranges gets sorted by eye. It works, but it is slow, inconsistent between shifts, and nearly impossible to audit later. OranGo replaces that manual process with a sensor-driven grading line paired with an iPad app, so a warehouse floor manager can watch grade counts update live as fruit rolls down the belt instead of waiting for someone to tally a clipboard at the end of the day.

## ✨ What OranGo Will Do

- 📊 **Live batch dashboard**: grade counts and quality breakdowns update on the iPad the moment a piece of fruit is graded, no manual entry required
- 👋 **Guided onboarding**: walks an operator through connecting a new grading session in a few taps
- 🍊 **Standard grading view**: pulls per-batch results straight from the shared backend, so the numbers on the iPad match the numbers everyone else sees

## 🛠️ Built With

| Layer | Stack |
|---|---|
| iOS client | Swift, SwiftUI |
| Backend (companion service) | Vapor, PostgreSQL |
| Minimum target | iOS 26.5 |

## 📁 Inside the Repo

```
OranGo/
├── App/              → app entry point
├── Root/             → root ContentView
├── Features/
│   ├── Dashboard/       → live batch dashboard (view + view model)
│   ├── Onboarding/      → guided setup for a new grading session
│   └── StandardGrading/ → standard grading results view
├── Models/            → data models (in progress)
├── Services/           → networking & business logic (in progress)
└── Extensions/         → shared utilities (in progress)
```

## 🚧 Where Things Stand

The feature-based architecture above is in place, and the views are being filled in one feature at a time. The companion Vapor + PostgreSQL backend that powers the live dashboard lives in its own service repository. If you are watching this space, expect the Dashboard and StandardGrading views to be the first ones to come alive.

## 🤝 Get Involved

Curious about the project, spotted something worth flagging, or want to compare notes on IoT grading systems? Open an issue or reach out, happy to talk through the approach.
