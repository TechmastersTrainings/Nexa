import React from 'react';
import { 
  ShieldCheck, 
  Smartphone, 
  KeyRound, 
  CheckCircle, 
  Cpu, 
  RefreshCw,
  Clock
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { ContactsManager } from './ContactsManager';
import { IncidentsLiveMap } from './IncidentsLiveMap';

export const Dashboard: React.FC = () => {
  const { user, token, refreshProfile, isLoading } = useAuth();

  if (!user || !token) return null;

  return (
    <div className="dashboard-wrapper animate-fade-in">
      {/* Top Welcome Banner */}
      <section className="welcome-banner">
        <div className="welcome-content">
          <div className="status-badge-live">
            <span className="pulsing-radar-dot"></span>
            <span>GUARDIAN SYSTEM ONLINE</span>
          </div>
          <h1 className="welcome-title">Welcome back, {user.full_name}</h1>
          <p className="welcome-subtitle">
            Your safety companion dashboard is active and synchronized with the PostgreSQL security cluster.
          </p>
        </div>

        <button 
          id="btn-refresh-dashboard"
          className="btn-refresh" 
          onClick={refreshProfile}
          disabled={isLoading}
        >
          <RefreshCw size={16} className={isLoading ? 'spin-icon' : ''} />
          <span>Refresh Status</span>
        </button>
      </section>

      {/* Critical Architecture Companion Notice */}
      <div className="disclosure-card">
        <div className="disclosure-icon-wrap">
          <Smartphone size={24} className="text-cyan" />
        </div>
        <div className="disclosure-body">
          <div className="disclosure-title">
            <span>Primary Safety Engine Notice</span>
            <span className="badge-pill-cyan">Architectural Disclosure</span>
          </div>
          <p className="disclosure-text">
            This web dashboard operates as a <strong>companion monitor and administration console</strong>. 
            Real-time offline voice trigger detection (using on-device Vosk ML), background incident queuing, 
            and physical hardware triggers are hosted natively on the <strong>Nexa Android Mobile Application</strong>.
          </p>
        </div>
      </div>

      {/* Main Grid: User Profile, Security Specifications, Contacts Manager */}
      <div className="dashboard-grid">
        {/* Card 1: User Profile & Identity Verification */}
        <div className="dashboard-card profile-card">
          <div className="card-header">
            <div className="card-header-icon">
              <ShieldCheck size={20} className="text-emerald" />
            </div>
            <div>
              <h2 className="card-title">Guardian Identity</h2>
              <span className="card-caption">Authenticated Profile Information</span>
            </div>
          </div>

          <div className="profile-details-list">
            <div className="profile-field">
              <span className="field-label">Full Name</span>
              <span className="field-val font-semibold">{user.full_name}</span>
            </div>

            <div className="profile-field">
              <span className="field-label">Email Address</span>
              <span className="field-val">{user.email}</span>
            </div>

            <div className="profile-field">
              <span className="field-label">Primary Mobile</span>
              <div className="phone-val-wrap">
                <span className="field-val">{user.phone_number}</span>
                <span className="status-chip chip-emerald">Active Account</span>
              </div>
            </div>

            <div className="profile-field">
              <span className="field-label">Account UUID</span>
              <span className="field-val font-mono text-xs">{user.id}</span>
            </div>

            <div className="profile-field">
              <span className="field-label">Account Status</span>
              <div className="status-chip-group">
                <span className="status-chip chip-emerald">
                  <CheckCircle size={12} /> Active
                </span>
                <span className="status-chip chip-indigo">
                  Tenant Isolated
                </span>
              </div>
            </div>

            <div className="profile-field">
              <span className="field-label">Registered Since</span>
              <span className="field-val text-xs text-muted">
                <Clock size={12} style={{ display: 'inline', marginRight: 4 }} />
                {new Date(user.created_at).toLocaleString()}
              </span>
            </div>
          </div>
        </div>

        {/* Card 2: Security & Encryption Engine */}
        <div className="dashboard-card security-card">
          <div className="card-header">
            <div className="card-header-icon">
              <KeyRound size={20} className="text-indigo" />
            </div>
            <div>
              <h2 className="card-title">Cryptographic Defense</h2>
              <span className="card-caption">Zero-Compromise Security Layers</span>
            </div>
          </div>

          <div className="security-specs-list">
            <div className="spec-item">
              <div className="spec-indicator active"></div>
              <div className="spec-info">
                <span className="spec-name">Argon2id Password Hashing</span>
                <span className="spec-detail">Memory-hard key derivation protecting user passwords against GPU attacks.</span>
              </div>
            </div>

            <div className="spec-item">
              <div className="spec-indicator active"></div>
              <div className="spec-info">
                <span className="spec-name">HMAC-SHA256 JWT Authorization</span>
                <span className="spec-detail">Time-limited scoped tokens with cryptographic signatures and automatic expiry.</span>
              </div>
            </div>

            <div className="spec-item">
              <div className="spec-indicator active"></div>
              <div className="spec-info">
                <span className="spec-name">Strict Row-Level Ownership</span>
                <span className="spec-detail">All database requests enforce verified user UUID boundaries.</span>
              </div>
            </div>

            <div className="spec-item">
              <div className="spec-indicator active"></div>
              <div className="spec-info">
                <span className="spec-name">PostgreSQL 17 ACID Persistence</span>
                <span className="spec-detail">Live database with schema migrations managed via Alembic.</span>
              </div>
            </div>
          </div>
        </div>

        {/* Card 3: Emergency Responders Management */}
        <ContactsManager />

        {/* Card 4: Platform Roadmap & Feature Readiness */}
        <div className="dashboard-card roadmap-card">
          <div className="card-header">
            <div className="card-header-icon">
              <Cpu size={20} className="text-cyan" />
            </div>
            <div>
              <h2 className="card-title">Platform Services Roadmap</h2>
              <span className="card-caption">Incremental 10-Phase Progression</span>
            </div>
          </div>

          <div className="roadmap-items">
            <div className="roadmap-row passed">
              <div className="roadmap-badge ready">Phase 1-4</div>
              <div className="roadmap-text">
                <span className="roadmap-title">Core Safety & Telemetry</span>
                <span className="roadmap-sub">Auth, Contacts, Offline Vosk Voice & GPS Durable Queue</span>
              </div>
              <span className="status-tag tag-ready">Complete</span>
            </div>

            <div className="roadmap-row passed">
              <div className="roadmap-badge ready">Phase 5-6</div>
              <div className="roadmap-text">
                <span className="roadmap-title">Alerts Engine & Live Monitor</span>
                <span className="roadmap-sub">Twilio automated SMS/Voice broadcast & Realtime Monitor</span>
              </div>
              <span className="status-tag tag-ready">Active</span>
            </div>

            <div className="roadmap-row upcoming">
              <div className="roadmap-badge">Phase 7</div>
              <div className="roadmap-text">
                <span className="roadmap-title">Voice-Stress ML Classification</span>
                <span className="roadmap-sub">Acoustic feature analysis & vocal distress score</span>
              </div>
              <span className="status-tag tag-next">Next Up</span>
            </div>

            <div className="roadmap-row pending">
              <div className="roadmap-badge">Phase 8</div>
              <div className="roadmap-text">
                <span className="roadmap-title">Community Safety Map</span>
                <span className="roadmap-sub">Danger zones heatmap & safe route navigation</span>
              </div>
              <span className="status-tag">Queued</span>
            </div>
          </div>
        </div>
      </div>

      {/* Live Incident & Distress Monitor */}
      <IncidentsLiveMap token={token} />
    </div>
  );
};
