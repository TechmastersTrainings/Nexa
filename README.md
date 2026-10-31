# Nexa AI — Women Safety & Emergency Intelligence Platform

[![Backend Tests](https://img.shields.io/badge/backend%20tests-34%20passed-brightgreen.svg)]()
[![Mobile Tests](https://img.shields.io/badge/mobile%20tests-8%20passed-brightgreen.svg)]()
[![Database](https://img.shields.io/badge/database-PostgreSQL%2017-blue.svg)]()
[![Architecture](https://img.shields.io/badge/status-100%25%20Completed-success.svg)]()

> **Nexa** is an autonomous, mission-critical personal safety intelligence platform engineered for women. It combines native on-device offline voice trigger recognition (Vosk), high-precision GPS telemetry with local durable offline queuing, automated telecom distress broadcast (SMS & Voice via Twilio), acoustic voice-stress ML classification, community hazard mapping, and an obsidian-styled real-time companion monitoring dashboard.

---

## 🏛️ Comprehensive 10-Phase Platform Architecture

| Phase | Component | Technologies | Implementation Highlights | Status |
|---|---|---|---|---|
| **Phase 1** | **Project Foundation & Security** | FastAPI, PostgreSQL 17, Alembic, Argon2id, PyJWT, React + Vite, Flutter | Cryptographic password hashing, scoped JWT token authorization, zero-compromise tenant isolation, authenticated profiles. | **100% Complete** |
| **Phase 2** | **Trusted Contacts & Account Security** | PostgreSQL, SQLAlchemy, React, Flutter | Max 5 prioritized responders, duplicate phone prevention, 6-digit OTP verification handshake, responder priority management. | **100% Complete** |
| **Phase 3** | **Offline On-Device Voice Recognition** | Vosk, Flutter Dart / Kotlin, AudioStream | 100% on-device speech keyword detection (`"help"`, `"bachao"`, `"save me"`), 30s cooldown duplicate suppression, zero cloud audio streaming. | **100% Complete** |
| **Phase 4** | **Location & Durable Offline Queue** | Geolocator, SharedPreferences, PostgreSQL | Real-time GPS coordinates, accuracy telemetry, local durable queue buffering offline distress incidents across network drops, idempotent sync. | **100% Complete** |
| **Phase 5** | **Emergency Alerts Delivery Engine** | Twilio REST API, PostgreSQL `incident_alert_logs` | Automated SMS and Voice call emergency broadcast to verified priority contacts with live Google Maps coordinate links and battery status. | **100% Complete** |
| **Phase 6** | **Live Monitor Companion Dashboard** | React + TypeScript, Vanilla CSS Glassmorphism | Real-time GPS telemetry feed, manual web SOS broadcast trigger, dispatch log tracking, battery status monitoring. | **100% Complete** |
| **Phase 7** | **Voice-Stress ML Classification Engine** | Python Acoustic Feature Extractor, Web Audio API | RMS amplitude, zero-crossing rate (ZCR), high-frequency energy ratio, and pitch shift extraction; calibrated distress score (0-100%). | **100% Complete** |
| **Phase 8** | **Community Safety Map & Danger Zones** | Haversine Spherical Distance, PostgreSQL, React, Flutter | Geospatial perimeter hazard clustering, safe haven sanctuaries (24/7 women police desks, hospitals), community validation upvotes. | **100% Complete** |
| **Phase 9** | **End-to-End Resilience Test Suite** | Pytest, Flutter Test, Starlette TestClient | Full lifecycle scenario: registration -> contacts -> voice trigger -> offline queue -> sync -> alert dispatch -> ML score -> safety zones. | **100% Complete** |
| **Phase 10** | **Dockerization & Production Orchestration** | Docker, Docker Compose, Nginx, Alpine | Multi-stage production containerization of PostgreSQL 17, FastAPI backend with automated Alembic migrations, and Nginx web server. | **100% Complete** |

---

## 🔒 Security & Privacy Guarantees

1. **Zero Mock Policy**: Every transaction, user profile, contact, incident, and alert log is backed by authentic database storage in PostgreSQL 17.
2. **On-Device Audio Privacy**: Voice recognition runs entirely on the local device using Vosk ML. Raw acoustic audio waveforms are never streamed to cloud servers.
3. **Ephemeral Distress Classification**: The Voice-Stress ML classifier processes audio snippets in memory only; audio bytes are discarded immediately after feature extraction.
4. **Idempotent Incident Sync**: Client-generated UUIDs ensure that duplicate sync attempts over unstable cellular networks never create redundant alert broadcasts.
5. **Strict Tenant Isolation**: All database queries enforce strict user UUID ownership boundaries, preventing cross-tenant information disclosure.

---

## 🚀 Quick Start & Development Setup

### 1. Prerequisites
- **Python**: 3.11+
- **Node.js**: 20+
- **Flutter SDK**: 3.24+
- **PostgreSQL**: 17 running on `localhost:5432` (or Docker)

### 2. Backend Setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate       # Windows PowerShell: .\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Run migrations
alembic upgrade head

# Run backend test suite (34 passing tests)
pytest tests -v

# Start FastAPI development server
uvicorn app.main:app --reload --port 8000
```
API Documentation will be available at: `http://localhost:8000/docs`

### 3. Web Companion Dashboard Setup
```bash
cd web
npm install
npm run build              # Production verification
npm run dev                # Development live server (http://localhost:5173)
```

### 4. Flutter Mobile Application Setup
```bash
cd mobile
flutter pub get
flutter test               # Run all 8 mobile unit and integration tests
flutter analyze            # Zero lints / static analysis clean
flutter run                # Run on Android emulator or connected device
```

---

## 🐳 Docker Production Orchestration

To run the complete production stack (PostgreSQL 17 + FastAPI Backend + Nginx Web Dashboard):

```bash
docker compose up -d --build
```

- **Web Dashboard**: `http://localhost:5173`
- **FastAPI Backend**: `http://localhost:8000`
- **API Health Check**: `http://localhost:8000/api/v1/health`
- **PostgreSQL 17**: `localhost:5432` (`nexa_safety_db`)

---

## 🧪 Verification & Test Results

```text
======================== 34 passed, 1 warning in 8.16s ========================
- backend/tests/test_auth.py: 5 passed
- backend/tests/test_contacts.py: 4 passed
- backend/tests/test_incidents.py: 5 passed
- backend/tests/test_alerts.py: 4 passed
- backend/tests/test_ml_stress.py: 5 passed
- backend/tests/test_safety_map.py: 4 passed
- backend/tests/test_e2e_resilience.py: 1 passed
- backend/tests/test_security.py: 4 passed
- backend/tests/test_health.py: 2 passed

All 8 Flutter mobile tests passed (100% pass rate) with 0 static analysis issues.
```

---

## 📜 License
Developed for the **Nexa AI Women Safety Platform** initiative. All rights reserved.
