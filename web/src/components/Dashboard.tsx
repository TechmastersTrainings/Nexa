import React, { useState } from 'react';
import { 
  ShieldCheck, 
  KeyRound, 
  CheckCircle, 
  RefreshCw,
  Clock,
  Radio,
  Users,
  MapPin,
  Activity,
  User,
  ShieldAlert,
  Lock,
  Smartphone
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { ContactsManager } from './ContactsManager';
import { IncidentsLiveMap } from './IncidentsLiveMap';
import { VoiceStressBench } from './VoiceStressBench';
import { CommunitySafetyMap } from './CommunitySafetyMap';

type DashboardTab = 'monitor' | 'contacts' | 'safetymap' | 'voicestress' | 'profile';

export const Dashboard: React.FC = () => {
  const { user, token, refreshProfile, isLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<DashboardTab>('monitor');

  if (!user || !token) return null;

  return (
    <div className="dashboard-wrapper animate-fade-in">
      {/* Top Guardian Command Center Header */}
      <section className="welcome-banner">
        <div className="welcome-content">
          <div className="status-badge-live">
            <span className="pulsing-radar-dot"></span>
            <span>GUARDIAN SENTINEL ACTIVE • 24/7 PROTECTION</span>
          </div>
          <h1 className="welcome-title">Command Center</h1>
          <p className="welcome-subtitle">
            Welcome back, <strong style={{ color: 'var(--text-primary)' }}>{user.full_name}</strong>. Real-time emergency telemetry, response network, and live vigilance are fully operational.
          </p>

          {/* Quick Metrics Bar */}
          <div className="command-metrics-bar">
            <div className="metric-chip">
              <ShieldAlert size={14} className="text-emerald" />
              <span>Status: <strong className="text-emerald">Protected</strong></span>
            </div>
            <div className="metric-chip">
              <Smartphone size={14} className="text-cyan" />
              <span>Device: <strong className="text-cyan">Linked</strong></span>
            </div>
            <div className="metric-chip">
              <Lock size={14} className="text-indigo" />
              <span>Encryption: <strong className="text-indigo">End-to-End</strong></span>
            </div>
          </div>
        </div>

        <div className="welcome-actions">
          <button 
            id="btn-refresh-dashboard"
            className="btn-refresh" 
            onClick={refreshProfile}
            disabled={isLoading}
            title="Synchronize live status"
          >
            <RefreshCw size={16} className={isLoading ? 'spin-icon' : ''} />
            <span>Sync Status</span>
          </button>
        </div>
      </section>

      {/* Modern Dashboard Navigation Tabs */}
      <nav className="dashboard-nav-tabs" aria-label="Dashboard views">
        <button
          id="tab-live-monitor"
          className={`dash-tab-btn ${activeTab === 'monitor' ? 'active' : ''}`}
          onClick={() => setActiveTab('monitor')}
        >
          <Radio size={18} className="tab-icon" />
          <span>Live Monitor</span>
        </button>

        <button
          id="tab-contacts"
          className={`dash-tab-btn ${activeTab === 'contacts' ? 'active' : ''}`}
          onClick={() => setActiveTab('contacts')}
        >
          <Users size={18} className="tab-icon" />
          <span>Emergency Responders</span>
        </button>

        <button
          id="tab-safety-map"
          className={`dash-tab-btn ${activeTab === 'safetymap' ? 'active' : ''}`}
          onClick={() => setActiveTab('safetymap')}
        >
          <MapPin size={18} className="tab-icon" />
          <span>Community Safety Map</span>
        </button>

        <button
          id="tab-voice-stress"
          className={`dash-tab-btn ${activeTab === 'voicestress' ? 'active' : ''}`}
          onClick={() => setActiveTab('voicestress')}
        >
          <Activity size={18} className="tab-icon" />
          <span>Acoustic Distress AI</span>
        </button>

        <button
          id="tab-profile-security"
          className={`dash-tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          <User size={18} className="tab-icon" />
          <span>Profile & Security</span>
        </button>
      </nav>

      {/* Tab Panels */}
      <div className="dashboard-tab-content">
        {/* TAB 1: Live Monitor & Incident Dispatch */}
        {activeTab === 'monitor' && (
          <div className="tab-pane animate-fade-in">
            <IncidentsLiveMap token={token} />
          </div>
        )}

        {/* TAB 2: Emergency Responders */}
        {activeTab === 'contacts' && (
          <div className="tab-pane animate-fade-in">
            <ContactsManager />
          </div>
        )}

        {/* TAB 3: Community Safety Map & Danger Zones */}
        {activeTab === 'safetymap' && (
          <div className="tab-pane animate-fade-in">
            <CommunitySafetyMap token={token} />
          </div>
        )}

        {/* TAB 4: Acoustic Distress AI */}
        {activeTab === 'voicestress' && (
          <div className="tab-pane animate-fade-in">
            <VoiceStressBench token={token} />
          </div>
        )}

        {/* TAB 5: Profile & Cryptographic Security */}
        {activeTab === 'profile' && (
          <div className="tab-pane animate-fade-in">
            <div className="dashboard-grid">
              {/* Profile Card */}
              <div className="dashboard-card profile-card">
                <div className="card-header">
                  <div className="card-header-icon">
                    <ShieldCheck size={20} className="text-emerald" />
                  </div>
                  <div>
                    <h2 className="card-title">Guardian Identity</h2>
                    <span className="card-caption">Verified Profile & Credentials</span>
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
                    <span className="field-label">Primary Mobile Phone</span>
                    <div className="phone-val-wrap">
                      <span className="field-val">{user.phone_number}</span>
                      <span className="status-chip chip-emerald">
                        <CheckCircle size={12} /> Active
                      </span>
                    </div>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Account Protection</span>
                    <div className="status-chip-group">
                      <span className="status-chip chip-emerald">
                        <CheckCircle size={12} /> Verified
                      </span>
                      <span className="status-chip chip-indigo">
                        Private Tenant
                      </span>
                    </div>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Member Since</span>
                    <span className="field-val text-xs text-muted">
                      <Clock size={12} style={{ display: 'inline', marginRight: 4 }} />
                      {new Date(user.created_at).toLocaleDateString(undefined, { 
                        year: 'numeric', 
                        month: 'long', 
                        day: 'numeric' 
                      })}
                    </span>
                  </div>
                </div>
              </div>

              {/* Security & Cryptography Defense Card */}
              <div className="dashboard-card security-card">
                <div className="card-header">
                  <div className="card-header-icon">
                    <KeyRound size={20} className="text-indigo" />
                  </div>
                  <div>
                    <h2 className="card-title">Cryptographic Defense</h2>
                    <span className="card-caption">Zero-Compromise Security Protections</span>
                  </div>
                </div>

                <div className="security-specs-list">
                  <div className="spec-item">
                    <div className="spec-indicator active"></div>
                    <div className="spec-info">
                      <span className="spec-name">Argon2id Password Defense</span>
                      <span className="spec-detail">Military-grade memory-hard key derivation shielding user credentials against brute-force attacks.</span>
                    </div>
                  </div>

                  <div className="spec-item">
                    <div className="spec-indicator active"></div>
                    <div className="spec-info">
                      <span className="spec-name">Encrypted Session Tokens</span>
                      <span className="spec-detail">Secure time-limited authentication tokens with instant revocation on logout.</span>
                    </div>
                  </div>

                  <div className="spec-item">
                    <div className="spec-indicator active"></div>
                    <div className="spec-info">
                      <span className="spec-name">Strict Data Boundary Isolation</span>
                      <span className="spec-detail">Your location traces, contacts, and distress logs are mathematically isolated to your account only.</span>
                    </div>
                  </div>

                  <div className="spec-item">
                    <div className="spec-indicator active"></div>
                    <div className="spec-info">
                      <span className="spec-name">High-Availability Cloud Sync</span>
                      <span className="spec-detail">Real-time persistent database synchronization ensuring instant disaster recovery and auditability.</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
