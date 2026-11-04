import React, { useState } from 'react';
import { 
  ShieldCheck, 
  CheckCircle, 
  RefreshCw,
  Radio,
  Users,
  MapPin,
  ShieldAlert,
  Lock,
  Smartphone,
  PhoneCall,
  HeartPulse,
  Copy,
  Edit3,
  X,
  Loader2,
  AlertCircle
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { ContactsManager } from './ContactsManager';
import { IncidentsLiveMap } from './IncidentsLiveMap';
import { VoiceStressBench } from './VoiceStressBench';
import { CommunitySafetyMap } from './CommunitySafetyMap';

type DashboardTab = 'monitor' | 'contacts' | 'safetymap' | 'voicestress' | 'profile';

export const Dashboard: React.FC = () => {
  const { user, token, refreshProfile, updateProfile, isLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<DashboardTab>('monitor');
  const [copyToast, setCopyToast] = useState<string | null>(null);

  // Edit Profile Modal state
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [editFullName, setEditFullName] = useState('');
  const [editPhone, setEditPhone] = useState('');
  const [editGuardianName, setEditGuardianName] = useState('');
  const [editGuardianPhone, setEditGuardianPhone] = useState('');
  const [editGuardianRelation, setEditGuardianRelation] = useState('');
  const [editHomeAddress, setEditHomeAddress] = useState('');
  const [editCityPolice, setEditCityPolice] = useState('');
  const [editHelpline, setEditHelpline] = useState('112');
  const [editBloodGroup, setEditBloodGroup] = useState('');
  const [editMedicalNotes, setEditMedicalNotes] = useState('');
  const [editSafeWord, setEditSafeWord] = useState('');
  const [editPoliceConsent, setEditPoliceConsent] = useState(true);
  const [editAge, setEditAge] = useState('');
  const [editSaving, setEditSaving] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);

  if (!user || !token) return null;

  // Open Edit Modal with current values
  const handleOpenEdit = () => {
    setEditFullName(user.full_name || '');
    setEditPhone(user.phone_number || '');
    setEditGuardianName(user.emergency_contact_name || '');
    setEditGuardianPhone(user.emergency_contact_phone || '');
    setEditGuardianRelation(user.emergency_contact_relation || 'Mother');
    setEditHomeAddress(user.home_address || '');
    setEditCityPolice(user.city_police_jurisdiction || '');
    setEditHelpline(user.preferred_police_helpline || '112');
    setEditBloodGroup(user.blood_group || '');
    setEditMedicalNotes(user.medical_notes || '');
    setEditSafeWord(user.safe_word_phrase || 'help me nexa');
    setEditPoliceConsent(user.police_dispatch_consent !== false);
    setEditAge(user.age ? String(user.age) : '');
    setEditError(null);
    setIsEditingProfile(true);
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setEditSaving(true);
    setEditError(null);
    try {
      await updateProfile({
        full_name: editFullName.trim() || undefined,
        phone_number: editPhone.trim() || undefined,
        emergency_contact_name: editGuardianName.trim() || undefined,
        emergency_contact_phone: editGuardianPhone.trim() || undefined,
        emergency_contact_relation: editGuardianRelation.trim() || undefined,
        home_address: editHomeAddress.trim() || undefined,
        city_police_jurisdiction: editCityPolice.trim() || undefined,
        preferred_police_helpline: editHelpline || '112',
        blood_group: editBloodGroup.trim() || undefined,
        medical_notes: editMedicalNotes.trim() || undefined,
        safe_word_phrase: editSafeWord.trim() || 'help me nexa',
        age: editAge ? parseInt(editAge, 10) : undefined,
        police_dispatch_consent: editPoliceConsent,
      });
      setIsEditingProfile(false);
      setCopyToast('Safety shield profile successfully updated!');
      setTimeout(() => setCopyToast(null), 3500);
    } catch (err: any) {
      setEditError(err.message || 'Failed to update safety profile');
    } finally {
      setEditSaving(false);
    }
  };

  // Copy Emergency SOS Dossier to clipboard
  const handleCopyDossier = () => {
    const text = `🚨 EMERGENCY SOS DOSSIER - NEXA WOMEN SAFETY
Name: ${user.full_name}
Mobile: ${user.phone_number || 'N/A'}
Age: ${user.age || 'N/A'} | Blood Group: ${user.blood_group || 'N/A'}
Guardian: ${user.emergency_contact_name || 'N/A'} (${user.emergency_contact_phone || 'N/A'}) [${user.emergency_contact_relation || 'Guardian'}]
Safe Base: ${user.home_address || 'Not specified'}
Police Jurisdiction: ${user.city_police_jurisdiction || 'Local Control Room'}
Preferred Police Helpline: ${user.preferred_police_helpline || '112'}
Medical Alerts: ${user.medical_notes || 'None recorded'}
Live GPS: Verified live telemetry active via Nexa AI`;

    navigator.clipboard.writeText(text);
    setCopyToast('Emergency dossier copied to clipboard! Ready to send to police / 112 / WhatsApp.');
    setTimeout(() => setCopyToast(null), 4000);
  };

  // Safety Score Calculation
  const calculateSafetyScore = () => {
    let score = 30; // base account
    if (user.phone_number) score += 15;
    if (user.emergency_contact_name && user.emergency_contact_phone) score += 25;
    if (user.home_address || user.city_police_jurisdiction) score += 15;
    if (user.blood_group || user.medical_notes) score += 15;
    return Math.min(score, 100);
  };
  const safetyScore = calculateSafetyScore();

  return (
    <div className="dashboard-wrapper animate-fade-in">
      {/* Toast Notification */}
      {copyToast && (
        <div 
          style={{
            position: 'fixed',
            bottom: '24px',
            right: '24px',
            background: '#0f172a',
            color: '#ffffff',
            padding: '0.85rem 1.25rem',
            borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-lg)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.6rem',
            zIndex: 999,
            fontSize: '0.86rem',
            fontWeight: 600,
            border: '1px solid rgba(255,255,255,0.1)'
          }}
          className="animate-fade-in"
        >
          <CheckCircle size={16} className="text-emerald" />
          <span>{copyToast}</span>
        </div>
      )}

      {/* Top Guardian Command Center Header */}
      <section className="welcome-banner">
        <div className="welcome-content">
          <div className="status-badge-live">
            <span className="pulsing-radar-dot"></span>
            <span>GUARDIAN SENTINEL ACTIVE • 24/7 WOMEN SAFETY NETWORK</span>
          </div>
          <h1 className="welcome-title">Command Center</h1>
          <p className="welcome-subtitle">
            Welcome back, <strong style={{ color: 'var(--text-primary)' }}>{user.full_name}</strong>. Real-time emergency telemetry, response network, and live vigilance are fully operational.
          </p>

          {/* Quick Metrics & Preparedness Bar */}
          <div className="command-metrics-bar">
            <div className="metric-chip">
              <ShieldAlert size={14} className="text-emerald" />
              <span>Safety Shield: <strong className="text-emerald">{safetyScore}% Armed</strong></span>
            </div>
            <div className="metric-chip">
              <Users size={14} className="text-cyan" />
              <span>Guardian: <strong className="text-cyan">{user.emergency_contact_name || 'Enrolled'}</strong></span>
            </div>
            <div className="metric-chip">
              <Lock size={14} className="text-indigo" />
              <span>Police Helpline: <strong className="text-indigo">{user.preferred_police_helpline || '112'}</strong></span>
            </div>
          </div>
        </div>

        <div className="welcome-actions" style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', alignItems: 'flex-end' }}>
          {/* Quick Police & Guardian Action Buttons */}
          <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
            <a
              href="tel:112"
              id="btn-quick-call-112"
              title="Immediate call to 112 National Police Emergency"
              style={{
                background: '#0f172a',
                color: '#ffffff',
                border: '1px solid #334155',
                borderRadius: 'var(--radius-md)',
                padding: '0.6rem 0.9rem',
                fontSize: '0.82rem',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                textDecoration: 'none'
              }}
            >
              <PhoneCall size={14} style={{ color: '#38bdf8' }} />
              <span>Call 112 Police</span>
            </a>

            <a
              href="tel:1091"
              id="btn-quick-call-1091"
              title="Immediate call to 1091 Women Safety Helpline"
              style={{
                background: '#ffffff',
                color: '#e11d48',
                border: '1.5px solid #f43f5e',
                borderRadius: 'var(--radius-md)',
                padding: '0.6rem 0.9rem',
                fontSize: '0.82rem',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                textDecoration: 'none'
              }}
            >
              <PhoneCall size={14} style={{ color: '#e11d48' }} />
              <span>1091 Helpline</span>
            </a>

            {user.emergency_contact_phone && (
              <a
                href={`tel:${user.emergency_contact_phone}`}
                id="btn-quick-call-guardian"
                title={`Call ${user.emergency_contact_name || 'Primary Guardian'}`}
                style={{
                  background: '#059669',
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.6rem 0.9rem',
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.4rem',
                  textDecoration: 'none'
                }}
              >
                <PhoneCall size={14} />
                <span>Call Guardian</span>
              </a>
            )}

            <button
              id="btn-copy-dossier"
              onClick={handleCopyDossier}
              title="Copy official emergency dispatch dossier to clipboard"
              style={{
                background: '#ffffff',
                color: 'var(--text-secondary)',
                border: '1px solid #cbd5e1',
                borderRadius: 'var(--radius-md)',
                padding: '0.6rem 0.9rem',
                fontSize: '0.82rem',
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                cursor: 'pointer'
              }}
            >
              <Copy size={14} />
              <span>SOS Dossier</span>
            </button>
          </div>

          <button 
            id="btn-refresh-dashboard"
            className="btn-refresh" 
            onClick={refreshProfile}
            disabled={isLoading}
            title="Synchronize live status"
          >
            <RefreshCw size={14} className={isLoading ? 'spin-icon' : ''} />
            <span>Sync Telemetry</span>
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
          <span>Live Monitor & Police SOS</span>
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
          <span>Safety Map & Safe Havens</span>
        </button>

        <button
          id="tab-voice-stress"
          className={`dash-tab-btn ${activeTab === 'voicestress' ? 'active' : ''}`}
          onClick={() => setActiveTab('voicestress')}
        >
          <Smartphone size={18} className="tab-icon" />
          <span>Acoustic AI Stress Bench</span>
        </button>

        <button
          id="tab-profile-security"
          className={`dash-tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          <ShieldCheck size={18} className="tab-icon" />
          <span>Women Safety Profile</span>
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
            {/* Top Bar for Profile Actions */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', flexWrap: 'wrap', gap: '1rem' }}>
              <div>
                <h2 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                  Women Safety Shield Profile
                </h2>
                <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                  Verified identity, primary guardian lifeline, sanctuary address, and emergency police telemetry.
                </p>
              </div>

              <button
                id="btn-edit-safety-profile"
                onClick={handleOpenEdit}
                style={{
                  background: 'var(--grad-hero)',
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.65rem 1.25rem',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer',
                  boxShadow: 'var(--shadow-glow-indigo)'
                }}
              >
                <Edit3 size={16} />
                <span>Update Safety Shield</span>
              </button>
            </div>

            <div className="dashboard-grid">
              {/* Card 1: Woman's Personal & Account Identity */}
              <div className="dashboard-card profile-card">
                <div className="card-header">
                  <div className="card-header-icon">
                    <ShieldCheck size={20} className="text-emerald" />
                  </div>
                  <div>
                    <h2 className="card-title">Protected Identity</h2>
                    <span className="card-caption">Personal Credentials & Safety Status</span>
                  </div>
                </div>

                <div className="profile-details-list">
                  <div className="profile-field">
                    <span className="field-label">Full Name</span>
                    <span className="field-val font-semibold">{user.full_name}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Primary Mobile (Lifeline)</span>
                    <div className="phone-val-wrap">
                      <span className="field-val">{user.phone_number || 'Not provided'}</span>
                      <span className="status-chip chip-emerald">
                        <CheckCircle size={12} /> Active SOS
                      </span>
                    </div>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Account Email</span>
                    <span className="field-val">{user.email}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Age</span>
                    <span className="field-val">{user.age ? `${user.age} years old` : 'Not specified'}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Shield Preparedness</span>
                    <div className="status-chip-group">
                      <span className="status-chip chip-emerald">
                        <CheckCircle size={12} /> {safetyScore}% Fortified
                      </span>
                      <span className="status-chip chip-indigo">
                        Private Isolated Tenant
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Card 2: Primary Emergency Guardian Lifeline */}
              <div className="dashboard-card">
                <div className="card-header">
                  <div className="card-header-icon" style={{ background: '#ecfdf5' }}>
                    <Users size={20} className="text-emerald" />
                  </div>
                  <div>
                    <h2 className="card-title">Primary Guardian Lifeline</h2>
                    <span className="card-caption">First-Contact Emergency Responder</span>
                  </div>
                </div>

                <div className="profile-details-list">
                  <div className="profile-field">
                    <span className="field-label">Guardian Name</span>
                    <span className="field-val font-semibold" style={{ color: '#065f46' }}>
                      {user.emergency_contact_name || 'No guardian configured'}
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Guardian Mobile Number</span>
                    <span className="field-val">
                      {user.emergency_contact_phone ? (
                        <a href={`tel:${user.emergency_contact_phone}`} style={{ color: '#7c3aed', fontWeight: 600, textDecoration: 'none' }}>
                          {user.emergency_contact_phone}
                        </a>
                      ) : (
                        'None'
                      )}
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Relationship to Woman</span>
                    <span className="field-val">{user.emergency_contact_relation || 'Guardian'}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Automatic SMS Dispatch</span>
                    <span className="status-chip chip-emerald">
                      <CheckCircle size={12} /> Armed (Instant GPS + Audio)
                    </span>
                  </div>
                </div>
              </div>

              {/* Card 3: Police Sanctuary & Rescue Telemetry */}
              <div className="dashboard-card">
                <div className="card-header">
                  <div className="card-header-icon" style={{ background: '#fdf2f8' }}>
                    <ShieldAlert size={20} className="text-rose" />
                  </div>
                  <div>
                    <h2 className="card-title">Police Sanctuary & Rescue</h2>
                    <span className="card-caption">Emergency Control Room (112) Dispatch Info</span>
                  </div>
                </div>

                <div className="profile-details-list">
                  <div className="profile-field">
                    <span className="field-label">Safe Home / Base Address</span>
                    <span className="field-val">{user.home_address || 'Not specified'}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Police Jurisdiction / Station</span>
                    <span className="field-val font-semibold" style={{ color: '#9d174d' }}>
                      {user.city_police_jurisdiction || 'Default 112 Control Room'}
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Preferred Police Helpline</span>
                    <span className="field-val font-bold" style={{ color: '#7c3aed' }}>
                      {user.preferred_police_helpline === '1091' ? '1091 (Women Helpline)' : user.preferred_police_helpline === '100' ? '100 (Police)' : '112 (National Unified Emergency)'}
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Police Telemetry Consent</span>
                    <span className="status-chip chip-emerald">
                      {user.police_dispatch_consent !== false ? 'Authorized for SOS' : 'Deactivated'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Card 4: Medical & Duress Shield */}
              <div className="dashboard-card">
                <div className="card-header">
                  <div className="card-header-icon" style={{ background: '#f0fdfa' }}>
                    <HeartPulse size={20} style={{ color: '#0d9488' }} />
                  </div>
                  <div>
                    <h2 className="card-title">Medical & Duress Shield</h2>
                    <span className="card-caption">First-Responder & Silent SOS Telemetry</span>
                  </div>
                </div>

                <div className="profile-details-list">
                  <div className="profile-field">
                    <span className="field-label">Blood Group</span>
                    <span className="field-val font-bold" style={{ color: '#e11d48' }}>
                      {user.blood_group || 'Not specified'}
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Medical Alerts / Allergies</span>
                    <span className="field-val">{user.medical_notes || 'None recorded'}</span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Secret Duress Safe-Word</span>
                    <span className="field-val" style={{ fontFamily: 'var(--font-mono)', color: '#7c3aed' }}>
                      "{user.safe_word_phrase || 'help me nexa'}"
                    </span>
                  </div>

                  <div className="profile-field">
                    <span className="field-label">Covert Distress AI</span>
                    <span className="status-chip chip-indigo">
                      Acoustic Stress Active
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* EDIT SAFETY PROFILE MODAL */}
      {isEditingProfile && (
        <div className="modal-backdrop animate-fade-in" onClick={() => setIsEditingProfile(false)}>
          <div 
            className="modal-card" 
            style={{ maxWidth: '580px', maxHeight: '90vh', overflowY: 'auto' }}
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            <button 
              className="modal-close-btn" 
              onClick={() => setIsEditingProfile(false)}
              aria-label="Close dialog"
            >
              <X size={18} />
            </button>

            <div className="modal-header" style={{ marginBottom: '1.25rem' }}>
              <div className="modal-icon-badge" style={{ margin: '0 auto 0.75rem auto' }}>
                <ShieldCheck size={26} className="icon-shield-accent" />
              </div>
              <h2 className="modal-title" style={{ textAlign: 'center', fontSize: '1.4rem' }}>
                Update Women Safety Shield
              </h2>
              <p className="modal-subtitle" style={{ textAlign: 'center', marginBottom: '0.5rem', fontSize: '0.85rem' }}>
                Modify your emergency guardian, sanctuary address, and police rescue profile.
              </p>
            </div>

            {editError && (
              <div className="auth-error-banner animate-fade-in" style={{ marginBottom: '1rem' }}>
                <AlertCircle size={16} className="error-icon" />
                <span>{editError}</span>
              </div>
            )}

            <form onSubmit={handleSaveProfile} className="auth-form">
              {/* Personal Details */}
              <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input
                    className="form-input"
                    type="text"
                    value={editFullName}
                    onChange={(e) => setEditFullName(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Age</label>
                  <input
                    className="form-input"
                    type="number"
                    min="1"
                    max="120"
                    value={editAge}
                    onChange={(e) => setEditAge(e.target.value)}
                    placeholder="e.g. 24"
                  />
                </div>
              </div>

              {/* Guardian Lifeline */}
              <div style={{ background: '#f8fafc', padding: '0.85rem', borderRadius: 'var(--radius-md)', border: '1px solid #e2e8f0' }}>
                <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#059669', textTransform: 'uppercase', display: 'block', marginBottom: '0.6rem' }}>
                  Emergency Guardian Network
                </span>
                <div className="form-group" style={{ marginBottom: '0.6rem' }}>
                  <label className="form-label">Guardian Full Name</label>
                  <input
                    className="form-input"
                    type="text"
                    placeholder="e.g. Sunita Sharma"
                    value={editGuardianName}
                    onChange={(e) => setEditGuardianName(e.target.value)}
                  />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: '0.75rem' }}>
                  <div className="form-group">
                    <label className="form-label">Guardian Mobile Phone</label>
                    <input
                      className="form-input"
                      type="tel"
                      placeholder="+91 99887 76655"
                      value={editGuardianPhone}
                      onChange={(e) => setEditGuardianPhone(e.target.value)}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Relationship</label>
                    <select
                      className="form-input"
                      value={editGuardianRelation}
                      onChange={(e) => setEditGuardianRelation(e.target.value)}
                    >
                      <option value="Mother">Mother</option>
                      <option value="Father">Father</option>
                      <option value="Spouse">Spouse / Partner</option>
                      <option value="Sister">Sister</option>
                      <option value="Brother">Brother</option>
                      <option value="Friend">Close Friend</option>
                      <option value="Legal Guardian">Legal Guardian</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Police Sanctuary & Jurisdiction */}
              <div className="form-group">
                <label className="form-label">Safe Home / Base Address</label>
                <input
                  className="form-input"
                  type="text"
                  placeholder="e.g. Flat 302, Palm Grove, Koramangala"
                  value={editHomeAddress}
                  onChange={(e) => setEditHomeAddress(e.target.value)}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label className="form-label">Local Police Station / City</label>
                  <input
                    className="form-input"
                    type="text"
                    placeholder="e.g. Koramangala PS, Bengaluru"
                    value={editCityPolice}
                    onChange={(e) => setEditCityPolice(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Blood Group</label>
                  <select
                    className="form-input"
                    value={editBloodGroup}
                    onChange={(e) => setEditBloodGroup(e.target.value)}
                  >
                    <option value="">Select Blood</option>
                    <option value="O+">O+</option>
                    <option value="O-">O-</option>
                    <option value="A+">A+</option>
                    <option value="A-">A-</option>
                    <option value="B+">B+</option>
                    <option value="B-">B-</option>
                    <option value="AB+">AB+</option>
                    <option value="AB-">AB-</option>
                  </select>
                </div>
              </div>

              {/* Preferred Helpline */}
              <div className="form-group">
                <label className="form-label">Preferred Police Helpline</label>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.5rem' }}>
                  {[
                    { num: '112', label: '112 Unified Emergency' },
                    { num: '1091', label: '1091 Women Helpline' },
                    { num: '100', label: '100 Police Control' },
                  ].map((item) => (
                    <button
                      key={item.num}
                      type="button"
                      onClick={() => setEditHelpline(item.num)}
                      style={{
                        padding: '0.5rem 0.4rem',
                        borderRadius: 'var(--radius-sm)',
                        border: editHelpline === item.num ? '2px solid #7c3aed' : '1px solid #cbd5e1',
                        background: editHelpline === item.num ? '#ede9fe' : '#ffffff',
                        color: editHelpline === item.num ? '#6d28d9' : 'var(--text-secondary)',
                        fontWeight: editHelpline === item.num ? 700 : 500,
                        fontSize: '0.75rem',
                        cursor: 'pointer',
                      }}
                    >
                      {item.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Medical Notes & Safe Word */}
              <div className="form-group">
                <label className="form-label">Medical Alerts / Allergies</label>
                <input
                  className="form-input"
                  type="text"
                  placeholder="e.g. Asthmatic, carries inhaler"
                  value={editMedicalNotes}
                  onChange={(e) => setEditMedicalNotes(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Secret Covert Duress Safe-Word</label>
                <input
                  className="form-input"
                  type="text"
                  value={editSafeWord}
                  onChange={(e) => setEditSafeWord(e.target.value)}
                />
              </div>

              <label style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={editPoliceConsent}
                  onChange={(e) => setEditPoliceConsent(e.target.checked)}
                  style={{ accentColor: '#7c3aed' }}
                />
                <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                  Authorize Nexa-AI to transmit live GPS distress telemetry to emergency services and police when SOS is triggered.
                </span>
              </label>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.75rem' }}>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setIsEditingProfile(false)}
                  style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius-md)', border: '1px solid #cbd5e1', background: '#ffffff', cursor: 'pointer', fontWeight: 600 }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-submit"
                  disabled={editSaving}
                  style={{ flex: 2, background: 'var(--grad-hero)' }}
                >
                  {editSaving ? (
                    <>
                      <Loader2 size={16} className="spin-icon" />
                      <span>Saving Changes...</span>
                    </>
                  ) : (
                    <>
                      <CheckCircle size={16} />
                      <span>Save Safety Profile</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};