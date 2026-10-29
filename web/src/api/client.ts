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
}

export const api = new ApiService();
