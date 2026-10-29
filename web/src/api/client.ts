// Nexa AI Women Safety Platform - API Client
const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

export interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  phone_number: string;
  is_active: boolean;
  is_verified: boolean;
  phone_verified: boolean;
  avatar_url?: string | null;
  created_at: string;
}

export interface AuthTokenResponse {
  access_token: string;
  token_type: string;
  expires_in_minutes: number;
}

export interface HealthStatus {
  status: string;
  database: string;
  version: string;
  service: string;
}

export interface TrustedContact {
  id: string;
  user_id: string;
  name: string;
  phone_number: string;
  relationship: string;
  priority_order: number;
  is_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface ContactCreatePayload {
  name: string;
  phone_number: string;
  relationship: string;
  priority_order: number;
}

export interface IncidentRecord {
  id: string;
  user_id: string;
  client_incident_id: string;
  trigger_type: string;
  status: string;
  latitude: number | null;
  longitude: number | null;
  accuracy_meters: number | null;
  location_timestamp: string | null;
  location_unavailable: boolean;
  battery_level: number | null;
  local_created_at: string;
  synchronized_at: string;
  created_at: string;
  updated_at: string;
}

export interface AlertLog {
  id: string;
  incident_id: string;
  recipient_contact_id: string | null;
  recipient_phone: string;
  message_body: string;
  provider: string;
  provider_message_id: string | null;
  delivery_status: string;
  status_details: string | null;
  attempt_number: number;
  error_message: string | null;
  created_at: string;
  updated_at: string;
}

export interface AlertDispatchResult {
  incident_id: string;
  dispatched_count: number;
  failed_count: number;
  alerts: AlertLog[];
}

class ApiService {
  async checkHealth(): Promise<HealthStatus> {
    const res = await fetch(`${API_BASE}/health`);
    if (!res.ok) {
      throw new Error(`Backend unavailable (HTTP ${res.status})`);
    }
    return res.json();
  }

  async register(data: {
    email: string;
    password: string;
    full_name: string;
    phone_number: string;
  }): Promise<UserProfile> {
    const res = await fetch(`${API_BASE}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });

    const json = await res.json();
    if (!res.ok) {
      const errorMsg = Array.isArray(json.detail)
        ? json.detail.map((e: any) => e.msg).join(', ')
        : json.detail || 'Registration failed';
      throw new Error(errorMsg);
    }
    return json;
  }

  async login(usernameOrEmail: string, password: string): Promise<AuthTokenResponse> {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: usernameOrEmail, password }),
    });

    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Invalid email or password');
    }
    return json;
  }

  async getMe(token: string): Promise<UserProfile> {
    const res = await fetch(`${API_BASE}/users/me`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Failed to fetch user profile');
    }
    return json;
  }

  // --- Trusted Contacts ---
  async getContacts(token: string): Promise<TrustedContact[]> {
    const res = await fetch(`${API_BASE}/contacts`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to fetch contacts');
    }
    return res.json();
  }

  async addContact(token: string, payload: ContactCreatePayload): Promise<TrustedContact> {
    const res = await fetch(`${API_BASE}/contacts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Failed to add contact');
    }
    return json;
  }

  async deleteContact(token: string, contactId: string): Promise<void> {
    const res = await fetch(`${API_BASE}/contacts/${contactId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to delete contact');
    }
  }

  async verifyContact(token: string, contactId: string, code: string): Promise<TrustedContact> {
    const res = await fetch(`${API_BASE}/contacts/${contactId}/verify?code=${encodeURIComponent(code)}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Verification failed');
    }
    return json;
  }

  // --- Incidents Telemetry ---
  async getIncidents(token: string): Promise<IncidentRecord[]> {
    const res = await fetch(`${API_BASE}/incidents`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to fetch incidents');
    }
    return res.json();
  }

  async recordIncident(
    token: string,
    payload: {
      client_incident_id: string;
      trigger_type: string;
      latitude?: number | null;
      longitude?: number | null;
      accuracy_meters?: number | null;
      location_unavailable?: boolean;
      battery_level?: number | null;
      local_created_at: string;
    }
  ): Promise<IncidentRecord> {
    const res = await fetch(`${API_BASE}/incidents`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Failed to record incident');
    }
    return json;
  }

  // --- Emergency Alerts Dispatch ---
  async dispatchAlerts(
    token: string,
    incidentId: string,
    alertType: 'sms' | 'voice' | 'all' = 'sms',
    recipientIds?: string[]
  ): Promise<AlertDispatchResult> {
    const res = await fetch(`${API_BASE}/alerts/dispatch`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        incident_id: incidentId,
        alert_type: alertType,
        recipient_ids: recipientIds || null,
      }),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Emergency alert dispatch failed');
    }
    return json;
  }

  async getAlertHistory(token: string): Promise<AlertLog[]> {
    const res = await fetch(`${API_BASE}/alerts/history`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to fetch alert history');
    }
    return res.json();
  }

  async getIncidentAlerts(token: string, incidentId: string): Promise<AlertLog[]> {
    const res = await fetch(`${API_BASE}/alerts/incident/${incidentId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to fetch incident alerts');
    }
    return res.json();
  }

  // --- Voice-Stress ML Classification ---
  async analyzeStress(
    token: string,
    payload: {
      raw_audio_base64?: string;
      sample_rate?: number;
      feature_override?: Record<string, number>;
    }
  ): Promise<StressAnalysisResult> {
    const res = await fetch(`${API_BASE}/ml/stress-analysis`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Vocal stress analysis failed');
    }
    return json;
  }

  async analyzeStressFile(token: string, file: File): Promise<StressAnalysisResult> {
    const formData = new FormData();
    formData.append('file', file);

    const res = await fetch(`${API_BASE}/ml/stress-analysis/file`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Audio file analysis failed');
    }
    return json;
  }

  // --- Community Safety Map & Danger Zones ---
  async getSafetyZones(lat: number, lng: number, radiusKm: number = 10, category?: string): Promise<SafetyReport[]> {
    let url = `${API_BASE}/safety-map/zones?lat=${lat}&lng=${lng}&radius_km=${radiusKm}`;
    if (category) {
      url += `&category=${encodeURIComponent(category)}`;
    }
    const res = await fetch(url);
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      throw new Error(json.detail || 'Failed to fetch safety zones');
    }
    return res.json();
  }

  async submitSafetyReport(token: string, payload: SafetyReportCreatePayload): Promise<SafetyReport> {
    const res = await fetch(`${API_BASE}/safety-map/reports`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Failed to submit safety report');
    }
    return json;
  }

  async upvoteSafetyReport(token: string, reportId: string): Promise<SafetyReport> {
    const res = await fetch(`${API_BASE}/safety-map/reports/${reportId}/upvote`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(json.detail || 'Upvote failed');
    }
    return json;
  }

  async getRecentSafetyReports(): Promise<SafetyReport[]> {
    const res = await fetch(`${API_BASE}/safety-map/reports/recent`);
    if (!res.ok) {
      return [];
    }
    return res.json();
  }
}

export interface AcousticFeatures {
  rms_energy: number;
  zero_crossing_rate: number;
  high_frequency_ratio: number;
  amplitude_variance: number;
  estimated_pitch_hz: number | null;
}

export interface StressAnalysisResult {
  distress_score: number;
  risk_level: 'NORMAL' | 'ELEVATED_STRESS' | 'CRITICAL_DISTRESS';
  confidence: number;
  features: AcousticFeatures;
  methodology: string;
  privacy_guarantee: string;
}

export interface SafetyReport {
  id: string;
  reporter_id: string | null;
  title: string;
  description: string | null;
  category: string;
  severity_level: number;
  latitude: number;
  longitude: number;
  radius_meters: number;
  is_verified: boolean;
  upvotes: number;
  distance_km?: number | null;
  created_at: string;
  updated_at: string;
}

export interface SafetyReportCreatePayload {
  title: string;
  description?: string;
  category: string;
  severity_level: number;
  latitude: number;
  longitude: number;
  radius_meters?: number;
}

export const api = new ApiService();


