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
            "severity_level": 1,
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
