import React, { useState } from 'react';
import { 
  Shield, 
  Lock, 
  Mail, 
  Phone, 
  User, 
  AlertCircle, 
  CheckCircle2, 
  X, 
  ArrowRight, 
  ArrowLeft,
  Loader2, 
  MapPin, 
  ShieldAlert,
  Users,
  Radio,
  Eye,
  EyeOff
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface AuthModalProps {
  isOpen: boolean;
  initialMode: 'login' | 'register';
  onClose: () => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({ isOpen, initialMode, onClose }) => {
  const { login, register, error, clearError } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>(initialMode);
  const [regStep, setRegStep] = useState<1 | 2 | 3>(1);
  
  // Step 1: Account & Personal Identification
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [age, setAge] = useState<string>('');

  // Step 2: Emergency Network & Primary Guardian
  const [guardianName, setGuardianName] = useState('');
  const [guardianPhone, setGuardianPhone] = useState('');
  const [guardianRelation, setGuardianRelation] = useState('Mother');

  // Step 3: Police Sanctuary, Medical & Duress Shield
  const [homeAddress, setHomeAddress] = useState('');
  const [cityPoliceJurisdiction, setCityPoliceJurisdiction] = useState('');
  const [preferredHelpline, setPreferredHelpline] = useState('112');
  const [bloodGroup, setBloodGroup] = useState('');
  const [medicalNotes, setMedicalNotes] = useState('');
  const [safeWord, setSafeWord] = useState('help me nexa');
  const [policeConsent, setPoliceConsent] = useState(true);
  const [showPassword, setShowPassword] = useState(false);

  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSwitchMode = (newMode: 'login' | 'register') => {
    clearError();
    setLocalError(null);
    setMode(newMode);
    setRegStep(1);
  };

  const handleNextStep = (e: React.MouseEvent) => {
    e.preventDefault();
    setLocalError(null);

    if (regStep === 1) {
      if (!fullName.trim()) {
        setLocalError('Full Name is required.');
        return;
      }
      if (!phone.trim()) {
        setLocalError('Primary mobile number is required for emergency dispatch.');
        return;
      }
      if (!email.trim()) {
        setLocalError('Email address is required.');
        return;
      }
      if (password.length < 8) {
        setLocalError('Password must be at least 8 characters long.');
        return;
      }
      setRegStep(2);
    } else if (regStep === 2) {
      if (!guardianName.trim()) {
        setLocalError('Primary Guardian name is required to ensure immediate SOS response.');
        return;
      }
      if (!guardianPhone.trim()) {
        setLocalError('Guardian contact phone number is required for distress SMS delivery.');
        return;
      }
      setRegStep(3);
    }
  };

  const handlePrevStep = (e: React.MouseEvent) => {
    e.preventDefault();
    setLocalError(null);
    if (regStep === 2) setRegStep(1);
    if (regStep === 3) setRegStep(2);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    clearError();

    if (mode === 'login') {
      if (!email || !password) {
        setLocalError('Please enter your email and password.');
        return;
      }
      setSubmitting(true);
      try {
        await login(email, password);
        onClose();
      } catch (err: any) {
        // error handled in context
      } finally {
        setSubmitting(false);
      }
      return;
    }

    // Register mode submission
    if (regStep !== 3) {
      return;
    }

    setSubmitting(true);
    try {
      if (guardianPhone.trim()) {
        localStorage.setItem('nexa_registered_guardian_phone', guardianPhone.trim());
      }
      if (guardianName.trim()) {
        localStorage.setItem('nexa_registered_guardian_name', guardianName.trim());
      }
      await register({
        email: email.trim(),
        password,
        full_name: fullName.trim(),
        phone_number: phone.trim(),
        age: age ? parseInt(age, 10) : undefined,
        // Guardian
        emergency_contact_name: guardianName.trim() || undefined,
        emergency_contact_phone: guardianPhone.trim() || undefined,
        emergency_contact_relation: guardianRelation || undefined,
        // Location & Police
        home_address: homeAddress.trim() || undefined,
        city_police_jurisdiction: cityPoliceJurisdiction.trim() || undefined,
        preferred_police_helpline: preferredHelpline,
        // Medical & Rescue
        blood_group: bloodGroup || undefined,
        medical_notes: medicalNotes.trim() || undefined,
        safe_word_phrase: safeWord.trim() || 'help me nexa',
        police_dispatch_consent: policeConsent,
      });
      onClose();
    } catch (err: any) {
      // Error handled by AuthContext
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-backdrop animate-fade-in">
      <div 
        className="modal-card" 
        style={{ 
          maxWidth: mode === 'register' ? '540px' : '430px', 
          maxHeight: 'min(92vh, 760px)', 
          overflowY: 'auto', 
          transition: 'max-width 0.25s ease' 
        }}
        role="dialog"
        aria-modal="true"
      >
        {/* Modal Close Button */}
        <button 
          id="btn-close-modal"
          className="modal-close-btn" 
          onClick={onClose}
          aria-label="Close dialog"
          title="Close dialog"
        >
          <X size={18} />
        </button>

        {/* Modal Header */}
        <div className="modal-header" style={{ marginBottom: '1.25rem' }}>
          <div className="modal-icon-badge" style={{ margin: '0 auto 0.75rem auto' }}>
            <Shield size={26} className="icon-shield-accent" />
          </div>
          <h2 className="modal-title" style={{ textAlign: 'center', fontSize: '1.45rem' }}>
            {mode === 'login' ? 'Access Guardian Portal' : 'Women Safety Sentinel Onboarding'}
          </h2>
          <p className="modal-subtitle" style={{ textAlign: 'center', marginBottom: '1rem', fontSize: '0.85rem' }}>
            {mode === 'login' 
              ? 'Sign in to access real-time emergency telemetry, active responders, and AI stress monitoring.' 
              : 'Configure your multi-layered defense shield, primary guardian lifeline, and police dispatch telemetry.'}
          </p>
        </div>

        {/* Mode Switch Tabs */}
        <div className="tab-switcher" style={{ marginBottom: '1.25rem' }}>
          <button 
            type="button"
            id="tab-btn-login"
            className={`tab-btn ${mode === 'login' ? 'active' : ''}`}
            onClick={() => handleSwitchMode('login')}
          >
            Sign In
          </button>
          <button 
            type="button"
            id="tab-btn-register"
            className={`tab-btn ${mode === 'register' ? 'active' : ''}`}
            onClick={() => handleSwitchMode('register')}
          >
            Create Protected Profile
          </button>
        </div>

        {/* Registration Safety Preparedness Stepper */}
        {mode === 'register' && (
          <div style={{ marginBottom: '1.5rem', background: '#f8fafc', padding: '0.85rem 1rem', borderRadius: 'var(--radius-md)', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#7c3aed', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
                {regStep === 1 && 'Step 1 of 3: Identity & Account'}
                {regStep === 2 && 'Step 2 of 3: Emergency Guardian Network'}
                {regStep === 3 && 'Step 3 of 3: Police & Medical Rescue Shield'}
              </span>
              <span style={{ fontSize: '0.75rem', fontWeight: 800, color: regStep === 3 ? '#059669' : '#0284c7' }}>
                {regStep === 1 && '35% Protected'}
                {regStep === 2 && '70% Protected'}
                {regStep === 3 && '100% Shielded 🛡️'}
              </span>
            </div>
            {/* Progress Bar */}
            <div style={{ height: '6px', background: '#e2e8f0', borderRadius: '999px', overflow: 'hidden' }}>
              <div 
                style={{ 
                  height: '100%', 
                  width: regStep === 1 ? '35%' : regStep === 2 ? '70%' : '100%', 
                  background: regStep === 3 ? 'var(--grad-safe)' : 'var(--grad-hero)',
                  transition: 'width 0.4s ease' 
                }} 
              />
            </div>
          </div>
        )}

        {/* Error Notification */}
        {(localError || error) && (
          <div className="auth-error-banner animate-fade-in" style={{ marginBottom: '1.25rem' }}>
            <AlertCircle size={16} className="error-icon" />
            <span>{localError || error}</span>
          </div>
        )}

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="auth-form">
          {mode === 'login' ? (
            /* --- LOGIN FORM --- */
            <>
              <div className="form-group">
                <label className="form-label" htmlFor="auth-email">Email Address</label>
                <div className="input-with-icon">
                  <Mail size={18} className="input-icon" />
                  <input
                    id="auth-email"
                    className="form-input"
                    type="email"
                    placeholder="name@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="auth-password">Password</label>
                <div className="input-with-icon" style={{ position: 'relative' }}>
                  <Lock size={18} className="input-icon" />
                  <input
                    id="auth-password"
                    className="form-input"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="••••••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    style={{ paddingRight: '2.5rem' }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: 'absolute',
                      right: '0.75rem',
                      background: 'none',
                      border: 'none',
                      color: 'var(--text-muted)',
                      cursor: 'pointer',
                      padding: 0,
                      display: 'flex',
                      alignItems: 'center'
                    }}
                    title={showPassword ? 'Hide password' : 'Show password'}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <button 
                type="submit" 
                id="btn-auth-submit"
                className="btn-submit"
                disabled={submitting}
                style={{ marginTop: '0.5rem' }}
              >
                {submitting ? (
                  <>
                    <Loader2 size={18} className="spin-icon" />
                    <span>Signing in securely...</span>
                  </>
                ) : (
                  <>
                    <span>Sign In to Guardian Portal</span>
                    <ArrowRight size={18} />
                  </>
                )}
              </button>

              <div style={{ textAlign: 'center', marginTop: '0.75rem', paddingTop: '0.85rem', borderTop: '1px solid #f1f5f9' }}>
                <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                  Don't have an account yet?{' '}
                  <button
                    type="button"
                    onClick={() => handleSwitchMode('register')}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: '#7c3aed',
                      fontWeight: 700,
                      cursor: 'pointer',
                      padding: 0
                    }}
                  >
                    Activate Safety Shield
                  </button>
                </span>
              </div>
            </>
          ) : (
            /* --- 3-STEP WOMEN SAFETY REGISTRATION --- */
            <>
              {/* STEP 1: Personal Identity & Credentials */}
              {regStep === 1 && (
                <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label" htmlFor="reg-name">Woman's Full Name *</label>
                    <div className="input-with-icon">
                      <User size={18} className="input-icon" />
                      <input
                        id="reg-name"
                        className="form-input"
                        type="text"
                        placeholder="e.g. Priya Sharma"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        required
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '0.75rem' }}>
                    <div className="form-group">
                      <label className="form-label" htmlFor="reg-phone">Mobile Phone (SOS Lifeline) *</label>
                      <div className="input-with-icon">
                        <Phone size={18} className="input-icon" />
                        <input
                          id="reg-phone"
                          className="form-input"
                          type="tel"
                          placeholder="+91 98765 43210"
                          value={phone}
                          onChange={(e) => setPhone(e.target.value)}
                          required
                        />
                      </div>
                    </div>

                    <div className="form-group">
                      <label className="form-label" htmlFor="reg-age">Age (Rescue ID)</label>
                      <input
                        id="reg-age"
                        className="form-input"
                        style={{ paddingLeft: '1rem' }}
                        type="number"
                        min="1"
                        max="120"
                        placeholder="e.g. 24"
                        value={age}
                        onChange={(e) => setAge(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label className="form-label" htmlFor="reg-email">Account Email *</label>
                    <div className="input-with-icon">
                      <Mail size={18} className="input-icon" />
                      <input
                        id="reg-email"
                        className="form-input"
                        type="email"
                        placeholder="priya@example.com"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        required
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label className="form-label" htmlFor="reg-password">Secure Password *</label>
                    <div className="input-with-icon">
                      <Lock size={18} className="input-icon" />
                      <input
                        id="reg-password"
                        className="form-input"
                        type="password"
                        placeholder="Minimum 8 characters"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                      />
                    </div>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      Protected with Argon2id cryptographic password hashing.
                    </span>
                  </div>

                  <button 
                    type="button" 
                    id="btn-step1-next"
                    className="btn-submit"
                    onClick={handleNextStep}
                    style={{ marginTop: '0.5rem' }}
                  >
                    <span>Next: Emergency Guardian Setup</span>
                    <ArrowRight size={18} />
                  </button>

                  <div style={{ textAlign: 'center', marginTop: '0.65rem' }}>
                    <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                      Already have an account?{' '}
                      <button
                        type="button"
                        onClick={() => handleSwitchMode('login')}
                        style={{ background: 'none', border: 'none', color: '#7c3aed', fontWeight: 700, cursor: 'pointer', padding: 0 }}
                      >
                        Sign in here
                      </button>
                    </span>
                  </div>
                </div>
              )}

              {/* STEP 2: Emergency Guardian Network */}
              {regStep === 2 && (
                <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ background: '#ecfdf5', border: '1px solid #a7f3d0', padding: '0.75rem 1rem', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Users size={20} className="text-emerald" style={{ flexShrink: 0 }} />
                    <p style={{ fontSize: '0.82rem', color: '#065f46', lineHeight: 1.4 }}>
                      <strong>Immediate Guardian Link:</strong> When an SOS or vocal distress is detected, Nexa automatically sends an emergency SMS with your live GPS location & audio distress link directly to this guardian.
                    </p>
                  </div>

                  <div className="form-group">
                    <label className="form-label" htmlFor="guardian-name">Primary Emergency Guardian Name *</label>
                    <div className="input-with-icon">
                      <User size={18} className="input-icon" />
                      <input
                        id="guardian-name"
                        className="form-input"
                        type="text"
                        placeholder="e.g. Sunita Sharma (Mother)"
                        value={guardianName}
                        onChange={(e) => setGuardianName(e.target.value)}
                        required
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: '0.75rem' }}>
                    <div className="form-group">
                      <label className="form-label" htmlFor="guardian-phone">Guardian Mobile Phone *</label>
                      <div className="input-with-icon">
                        <Phone size={18} className="input-icon" />
                        <input
                          id="guardian-phone"
                          className="form-input"
                          type="tel"
                          placeholder="+91 99887 76655"
                          value={guardianPhone}
                          onChange={(e) => setGuardianPhone(e.target.value)}
                          required
                        />
                      </div>
                    </div>

                    <div className="form-group">
                      <label className="form-label" htmlFor="guardian-relation">Relationship</label>
                      <select
                        id="guardian-relation"
                        className="form-input"
                        style={{ paddingLeft: '0.85rem' }}
                        value={guardianRelation}
                        onChange={(e) => setGuardianRelation(e.target.value)}
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

                  <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem' }}>
                    <button 
                      type="button" 
                      id="btn-step2-back"
                      className="btn-secondary"
                      onClick={handlePrevStep}
                      style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius-md)', border: '1px solid #cbd5e1', background: '#ffffff', cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
                    >
                      <ArrowLeft size={16} />
                      <span>Back</span>
                    </button>
                    <button 
                      type="button" 
                      id="btn-step2-next"
                      className="btn-submit"
                      onClick={handleNextStep}
                      style={{ flex: 2 }}
                    >
                      <span>Next: Police & Medical Shield</span>
                      <ArrowRight size={18} />
                    </button>
                  </div>
                </div>
              )}

              {/* STEP 3: Police Sanctuary, Medical & Duress Shield */}
              {regStep === 3 && (
                <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
                  <div style={{ background: '#fdf2f8', border: '1px solid #fbcfe8', padding: '0.75rem 1rem', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <ShieldAlert size={20} className="text-rose" style={{ flexShrink: 0 }} />
                    <p style={{ fontSize: '0.82rem', color: '#9d174d', lineHeight: 1.4 }}>
                      <strong>Police Dispatch Telemetry:</strong> Equips local emergency control rooms (PCR) and first responders with your sanctuary address and rescue profile for rapid dispatch.
                    </p>
                  </div>

                  <div className="form-group">
                    <label className="form-label" htmlFor="safe-address">Safe Home / Base Address</label>
                    <div className="input-with-icon">
                      <MapPin size={18} className="input-icon" />
                      <input
                        id="safe-address"
                        className="form-input"
                        type="text"
                        placeholder="e.g. Flat 302, Palm Grove, 12th Main Road"
                        value={homeAddress}
                        onChange={(e) => setHomeAddress(e.target.value)}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: '0.75rem' }}>
                    <div className="form-group">
                      <label className="form-label" htmlFor="police-jurisdiction">Local Police Station / City</label>
                      <input
                        id="police-jurisdiction"
                        className="form-input"
                        style={{ paddingLeft: '1rem' }}
                        type="text"
                        placeholder="e.g. Koramangala PS, Bengaluru"
                        value={cityPoliceJurisdiction}
                        onChange={(e) => setCityPoliceJurisdiction(e.target.value)}
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label" htmlFor="blood-group">Blood Group</label>
                      <select
                        id="blood-group"
                        className="form-input"
                        style={{ paddingLeft: '0.85rem' }}
                        value={bloodGroup}
                        onChange={(e) => setBloodGroup(e.target.value)}
                      >
                        <option value="">Select Blood Group</option>
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

                  {/* Preferred Police Helpline Pill Selector */}
                  <div className="form-group">
                    <label className="form-label">Preferred Emergency Helpline</label>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.5rem' }}>
                      {[
                        { num: '112', label: '112 Unified Emergency' },
                        { num: '1091', label: '1091 Women Helpline' },
                        { num: '100', label: '100 Police Control' },
                      ].map((item) => (
                        <button
                          key={item.num}
                          type="button"
                          onClick={() => setPreferredHelpline(item.num)}
                          style={{
                            padding: '0.5rem 0.4rem',
                            borderRadius: 'var(--radius-sm)',
                            border: preferredHelpline === item.num ? '2px solid #7c3aed' : '1px solid #cbd5e1',
                            background: preferredHelpline === item.num ? '#ede9fe' : '#ffffff',
                            color: preferredHelpline === item.num ? '#6d28d9' : 'var(--text-secondary)',
                            fontWeight: preferredHelpline === item.num ? 700 : 500,
                            fontSize: '0.75rem',
                            cursor: 'pointer',
                            textAlign: 'center',
                          }}
                        >
                          {item.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Medical Notes / Allergies */}
                  <div className="form-group">
                    <label className="form-label" htmlFor="med-notes">Emergency Medical Notes / Allergies (Optional)</label>
                    <input
                      id="med-notes"
                      className="form-input"
                      style={{ paddingLeft: '1rem' }}
                      type="text"
                      placeholder="e.g. Asthmatic, carries inhaler / Penicillin allergy"
                      value={medicalNotes}
                      onChange={(e) => setMedicalNotes(e.target.value)}
                    />
                  </div>

                  {/* Secret Duress Safe-Word */}
                  <div className="form-group">
                    <label className="form-label" htmlFor="safe-word">
                      Secret Covert Duress Safe-Word
                    </label>
                    <div className="input-with-icon">
                      <Radio size={18} className="input-icon" />
                      <input
                        id="safe-word"
                        className="form-input"
                        type="text"
                        placeholder="help me nexa"
                        value={safeWord}
                        onChange={(e) => setSafeWord(e.target.value)}
                      />
                    </div>
                    <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                      Speaking or whispering this secret phrase triggers silent SOS broadcasts.
                    </span>
                  </div>

                  {/* Police Consent Checkbox */}
                  <label style={{ display: 'flex', alignItems: 'flex-start', gap: '0.6rem', cursor: 'pointer', marginTop: '0.2rem' }}>
                    <input
                      type="checkbox"
                      checked={policeConsent}
                      onChange={(e) => setPoliceConsent(e.target.checked)}
                      style={{ marginTop: '0.2rem', accentColor: '#7c3aed' }}
                    />
                    <span style={{ fontSize: '0.76rem', color: 'var(--text-secondary)', lineHeight: 1.35 }}>
                      Authorize Nexa-AI to transmit live GPS distress telemetry and identification dossier to local police & emergency services when SOS is triggered.
                    </span>
                  </label>

                  <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem' }}>
                    <button 
                      type="button" 
                      id="btn-step3-back"
                      className="btn-secondary"
                      onClick={handlePrevStep}
                      disabled={submitting}
                      style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius-md)', border: '1px solid #cbd5e1', background: '#ffffff', cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
                    >
                      <ArrowLeft size={16} />
                      <span>Back</span>
                    </button>
                    <button 
                      type="submit" 
                      id="btn-complete-registration"
                      className="btn-submit"
                      disabled={submitting}
                      style={{ flex: 2, background: 'var(--grad-hero)' }}
                    >
                      {submitting ? (
                        <>
                          <Loader2 size={18} className="spin-icon" />
                          <span>Activating Shield...</span>
                        </>
                      ) : (
                        <>
                          <Shield size={18} />
                          <span>Complete 100% Protected Registration</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </form>

        <div className="modal-footer-note" style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid #f1f5f9' }}>
          <CheckCircle2 size={14} className="text-emerald" />
          <span style={{ fontSize: '0.76rem' }}>
            256-bit encrypted tenant storage • Compliant with Indian emergency dispatch standards (112 / 1091).
          </span>
        </div>
      </div>
    </div>
  );
};