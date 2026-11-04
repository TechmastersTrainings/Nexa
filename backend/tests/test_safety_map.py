import uuid
import pytest
from fastapi.testclient import TestClient


def get_auth_token(client: TestClient) -> str:
    email = f"map_user_{uuid.uuid4().hex[:6]}@example.com"
    phone = f"+9198777{uuid.uuid4().hex[:5]}"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!Secure", "full_name": "Map Reporter", "phone_number": phone},
    )
    res = client.post("/api/v1/auth/login", json={"email": email, "password": "Password123!Secure"})
    return res.json()["access_token"]


def test_create_safety_report_and_safe_haven(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Report a hazard
    hazard_payload = {
        "title": "Dimly Lit Alley near Metro Exit 2",
        "description": "Streetlights are broken and several incidents of harassment have occurred here.",
        "category": "poor_lighting",
        "severity_level": 4,
        "latitude": 12.9716,
        "longitude": 77.5946,
        "radius_meters": 120.0,
    }
    res = client.post("/api/v1/safety-map/reports", headers=headers, json=hazard_payload)
    assert res.status_code == 201
    hazard = res.json()
    assert hazard["title"] == hazard_payload["title"]
    assert hazard["category"] == "poor_lighting"
    assert hazard["severity_level"] == 4
    assert hazard["upvotes"] == 0

    # 2. Report a safe haven (24x7 all-women police desk)
    haven_payload = {
        "title": "24/7 Women Police Assistance Booth",
        "description": "Always staffed with female officers and CCTV surveillance.",
        "category": "police_booth",
        "severity_level": 1,
        "latitude": 12.9730,
        "longitude": 77.5960,
        "radius_meters": 50.0,
    }
    res2 = client.post("/api/v1/safety-map/reports", headers=headers, json=haven_payload)
    assert res2.status_code == 201
    haven = res2.json()
    assert haven["category"] == "police_booth"
    assert haven["is_verified"] is True  # Safe havens auto-verified


def test_geospatial_radius_query(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Location A: Bangalore MG Road (12.9750, 77.6090)
    client.post(
        "/api/v1/safety-map/reports",
        headers=headers,
        json={
            "title": "MG Road Corridor Safe Haven",
            "category": "safe_haven",
            "severit
            
            
            
            No more older messages
            Conversation Log
            Is it something the website helps to send the SMS and call local police? -- I think wenedto connect the detailed information of the woman while registration, just name,password, mobile numberwould nt be sounding that 100% of the project what we are developing.
            This should sound like asafetyness that the platform provides to the woman. Did you understand what I am expecting 
            Yes, I completely understand what you are expecting. You have hit on the single most crucial aspect of this project: Nexa-AI is not a generic web app; it is a dedicated, life-saving Women's Safety & Emergency Response platform.
            
            A standard registration asking only for Name, Email, and Password feels detached and gives no sense of protection or preparedness. If a woman is in distress and triggers an SOS, local police and first responders cannot effectively locate or rescue her without actionable details. The onboarding experience itself must convey "safetyness," trust, and active protection.
            
            1. Does the platform send SMS and call local police?
            Yes. Here is how the emergency dispatch architecture works:
            
            Distress SMS to Emergency Contacts & Police:
            Powered by 
            alert_service.py
             via the Twilio SMS Gateway.
            When an SOS is triggered (via one-tap panic button, voice stress detection, or mobile sensor), the system instantly broadcasts an emergency distress message containing:
            Live GPS Coordinates with Google Maps link (https://maps.google.com/?q=lat,lng)
            Victim's Identity & Battery Level
            Trigger reason (e.g. VOICE_DISTRESS, PANIC_BUTTON, ZONE_BREACH)
            Calling Local Police & Automated Voice Distress:
            Automated Voice Dispatch: The backend's Twilio Voice integration places automated emergency calls reciting the distress message and coordinates to registered guardians.
            Instant Local Police Calling (Web & Mobile): Direct one-tap click-to-dial for national emergency numbers (112 unified emergency, 1091 Women's Helpline, or 100 Police Control Room) directly connected to the local police control room.
            Police Dispatch Dossier: An emergency snapshot containing the woman’s photo, home address, blood group, primary emergency contacts, and live coordinates can be formatted directly for police dispatchers.
            2. What Detailed Information Should We Collect During Registration?
            To instill complete confidence and make the platform 100% focused on her safety, the registration should be structured as a Guided "Safety Shield Onboarding":
            
            Dimension	Critical Information Needed	Why It Provides "Safetyness"
            1. Identity & Verification	Full name, safe email, primary mobile with OTP verification, Age / Date of Birth	Establishes verified identity for official police reporting.
            2. Primary Emergency Guardian	Guardian Name, Relationship (Mother, Father, Spouse, Friend), Guardian Phone Number	Guarantees she is never left without at least 1 verified responder from minute one.
            3. Location & Police Jurisdiction	Home / Base Address, City, State, Nearest Police Station / District	Police control rooms (PCRs) route calls by station jurisdiction. Knowing her base location speeds up dispatch.
            4. Medical & Rescue Identifiers	Blood Group, Emergency Medical Notes / Allergies (optional)	Crucial for first responders and paramedics in emergency rescue scenarios.
            5. Duress & Covert Protection	Secret Distress Safe-Word (e.g. "Help me Nexa" or custom secret phrase), Police Auto-Dispatch consent	Gives her covert ways to call for help even if an attacker is watching her phone.
            3. Proposed Plan to Elevate the Platform
            Upgrade Database Model & Schemas:
            In 
            backend/app/models/user.py
             and 
            backend/app/schemas/user.py
            , add:
            emergency_contact_name, emergency_contact_phone, emergency_contact_relation
            home_address, city_police_jurisdiction
            blood_group, medical_notes
            police_dispatch_consent
            Multi-Step "Safety Sentinel" Registration Wizard:
            Update 
            AuthModal.tsx
             to offer a sleek, reassuring step-by-step registration with a "Safety Preparedness Score" (e.g., reaching 100% Shielded).
            Dedicated Emergency Police Quick-Action:
            Add a prominent "Call Police (112 / 1091)" quick-dial button and emergency police alert trigger right in the dashboard banner and live incident map.
            Would you like to proceed with this?
            If you're aligned, we can begin updating the Backend User models/schemas and then build the Safety Onboarding registration flow in the frontend.
            
            Proceed
            We have completely upgraded both the backend and frontend to transform the onboarding and dashboard experience into a true Women Safety & Emergency Response ecosystem.
            
            What Was Implemented
            1. Backend: Women's Emergency Protection Schema & Alerts
            Database & Alembic Migration (
            c83df2e94711_add_women_safety_profile_fields_to_users.py
            ):
            Primary Guardian Lifeline: emergency_contact_name, emergency_contact_phone, emergency_contact_relation
            Police Jurisdiction & Sanctuary: home_address, city_police_jurisdiction, preferred_police_helpline (112 default, 1091, 100), police_dispatch_consent
            Medical & Rescue Telemetry: blood_group, medical_notes, age
            Models & Schemas (
            user.py
            , 
            schemas/user.py
            ):
            Added validation and serialization for all safety fields in UserCreate, UserUpdate, and UserResponse.
            Automatic Guardian Enrolment (
            user_repository.py
            ):
            When a woman registers her guardian, the system automatically creates a verified TrustedContact in the emergency responder database, ensuring immediate SOS dispatch readiness.
            Rescue Dossier in SMS / Distress Dispatch (
            alert_service.py
            ):
            Emergency distress SMS and Twilio voice calls now include actionable rescue metadata:
            EMERGENCY SOS ALERT! Nexa Safety: Priya Sharma triggered an SOS distress signal. Location: https://maps.google.com/?q=... | SafeShield: [Blood: O+, Jurisdiction: Koramangala PS, Guardian: Sunita Sharma (+919988776655)]. Dispatch police/responders immediately!
            
            2. Frontend: 3-Step "Safety Sentinel" Onboarding Wizard
            In 
            AuthModal.tsx
            , the generic registration form has been replaced with a guided onboarding wizard with a live Safety Preparedness Score:
            
            Step 1: Protected Identity (35% Protected)
            Full Name, Mobile Phone (Lifeline), Account Email, Age (Rescue ID), and Argon2id Password.
            Step 2: Guardian Network (70% Protected)
            Primary Guardian Name, Phone, and Relationship (Mother, Father, Spouse, Sister, Friend, etc.).
            Explanatory reassurance banner detailing how automated SMS & GPS live tracking work.
            Step 3: Police Sanctuary, Medical & Duress Shield (100% Shielded 🛡️)
            Safe Base Address & Nearest Police Station / District.
            Preferred Police Helpline selection (112 National Emergency, 1091 Women Helpline, 100 Police Control Room).
            Blood Group & Emergency Medical Notes / Allergies (e.g. Asthmatic / carries inhaler).
            Secret Duress Safe-Word (defaults to "help me nexa", custom covert phrase for silent SOS).
            Police Dispatch Consent authorization.
            3. Dashboard: Quick Police Dialers & Emergency Dossier
            In 
            Dashboard.tsx
             and 
            IncidentsLiveMap.tsx
            :
            
            Direct Police Quick-Dial Buttons:
            One-tap click-to-call links for Call 112 (Police) and 1091 Women Helpline.
            Direct Call Guardian button right in the top banner.
            One-Click "SOS Dossier" Copy:
            Copies a structured distress brief (Name, Age, Blood Group, Home Base, Police Jurisdiction, Guardian Contact, GPS link) to clipboard, ready to pass to 112 dispatchers or family over WhatsApp/SMS.
            Women Safety Profile Cards:
            Displays 4 dedicated cards: Protected Identity, Primary Guardian Lifeline, Police Sanctuary & Rescue, and Medical & Duress Shield.
            Interactive Profile Editor:
            Women can update their guardian, safe address, blood group, or covert safe-word at any time via an "Update Safety Shield" modal.
            Verification
            Ran syntax and dependency verification on all backend Python modules: passed.
            Verified the Alembic migration script syntax: passed.
            Ran TypeScript build (tsc -b && vite build): completed in 1.45s with 0 errors.
            Fire up the servers, before create a beautiful homepage then a current page after login
            I have updated the homepage and dashboard, and I am currently verifying the test suite before firing up the backend and frontend servers. I will update you as soon as the test finishes.
            
            y_level": 1,
            "latitude": 12.9750,
            "longitude": 77.6090,
            "radius_meters": 80.0,
        },
    )

    # Location B: Delhi (28.6139, 77.2090) -> ~1700 km away!
    client.post(
        "/api/v1/safety-map/reports",
        headers=headers,
        json={
            "title": "Connaught Place Safe Zone",
            "category": "safe_haven",
            "severity_level": 1,
            "latitude": 28.6139,
            "longitude": 77.2090,
            "radius_meters": 100.0,
        },
    )

    # Query Bangalore center with 5km radius -> MG Road should be found, Delhi must be excluded
    res = client.get(
        "/api/v1/safety-map/zones",
        params={"lat": 12.9716, "lng": 77.5946, "radius_km": 5.0},
    )
    assert res.status_code == 200
    zones = res.json()
    titles = [z["title"] for z in zones]
    assert "MG Road Corridor Safe Haven" in titles
    assert "Connaught Place Safe Zone" not in titles

    # Verify distance_km is populated and reasonable
    mg_road = next(z for z in zones if z["title"] == "MG Road Corridor Safe Haven")
    assert mg_road["distance_km"] is not None
    assert mg_road["distance_km"] < 5.0


def test_category_filter(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/safety-map/reports",
        headers=headers,
        json={
            "title": "Hospital Emergency Care 24x7",
            "category": "hospital",
            "severity_level": 1,
            "latitude": 12.9720,
            "longitude": 77.5950,
        },
    )

    # Filter specifically for category=hospital
    res = client.get(
        "/api/v1/safety-map/zones",
        params={"lat": 12.9720, "lng": 77.5950, "radius_km": 2.0, "category": "hospital"},
    )
    assert res.status_code == 200
    zones = res.json()
    assert all(z["category"] == "hospital" for z in zones)


def test_community_upvoting(client: TestClient):
    token = get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    report = client.post(
        "/api/v1/safety-map/reports",
        headers=headers,
        json={
            "title": "Underpass Lighting Failure",
            "category": "poor_lighting",
            "severity_level": 3,
            "latitude": 12.9710,
            "longitude": 77.5930,
        },
    ).json()

    assert report["upvotes"] == 0

    # Upvote report
    up_res = client.post(f"/api/v1/safety-map/reports/{report['id']}/upvote", headers=headers)
    assert up_res.status_code == 200
    updated = up_res.json()
    assert updated["upvotes"] == 1
