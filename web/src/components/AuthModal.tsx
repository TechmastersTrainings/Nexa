import React, { useState } from 'react';
import { Shield, Lock, Mail, Phone, User, AlertCircle, CheckCircle2, X, ArrowRight, Loader2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface AuthModalProps {
  isOpen: boolean;
  initialMode: 'login' | 'register';
  onClose: () => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({ isOpen, initialMode, onClose }) => {
  const { login, register, error, clearError } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>(initialMode);
  
  // Form fields
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSwitchMode = (newMode: 'login' | 'register') => {
    clearError();
    setLocalError(null);
    setMode(newMode);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    clearError();

    if (!email || !password) {
      setLocalError('Please fill in all required credentials.');
      return;
    }

    if (mode === 'register') {
      if (!fullName.trim()) {
        setLocalError('Full name is required.');
        return;
      }
      if (!phone.trim()) {
        setLocalError('Contact phone number is required for emergency dispatch.');
        return;
      }
      if (password.length < 8) {
        setLocalError('Password must be at least 8 characters long.');
        return;
      }
    }

    setSubmitting(true);
    try {
      if (mode === 'login') {
        await login(email, password);
      } else {
        await register({
          email: email.trim(),
          password,
          full_name: fullName.trim(),
          phone_number: phone.trim(),
        });
      }
      onClose();
    } catch (err: any) {
      // Error handled by AuthContext or caught here
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-backdrop animate-fade-in" onClick={onClose}>
      <div 
        className="modal-card" 
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        {/* Modal Close Button */}
        <button 
          id="btn-close-modal"
          className="modal-close-btn" 
          onClick={onClose}
          aria-label="Close dialog"
        >
          <X size={18} />
        </button>

        {/* Modal Header */}
        <div className="modal-header">
          <div className="modal-icon-badge">
            <Shield size={24} className="icon-shield-accent" />
          </div>
          <h2 className="modal-title">
            {mode === 'login' ? 'Access Guardian Portal' : 'Create Guardian Account'}
          </h2>
          <p className="modal-desc">
            {mode === 'login' 
              ? 'Sign in to access your synchronized safety dashboard and emergency preferences.' 
              : 'Join Nexa AI to protect yourself and configure your trusted responder network.'}
          </p>
        </div>

        {/* Mode Switch Tabs */}
        <div className="tab-switcher">
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
            New Account
          </button>
        </div>

        {/* Error Notification */}
        {(localError || error) && (
          <div className="auth-error-banner animate-fade-in">
            <AlertCircle size={16} className="error-icon" />
            <span>{localError || error}</span>
          </div>
        )}

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="auth-form">
          {mode === 'register' && (
            <>
              <div className="form-group">
                <label htmlFor="reg-name">Full Name</label>
                <div className="input-wrapper">
                  <User size={18} className="field-icon" />
                  <input
                    id="reg-name"
                    type="text"
                    placeholder="e.g. Elena Rostova"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="reg-phone">Emergency Phone Number</label>
                <div className="input-wrapper">
                  <Phone size={18} className="field-icon" />
                  <input
                    id="reg-phone"
                    type="tel"
                    placeholder="+1 555 019 2834"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    required
                  />
                </div>
                <span className="field-help">Required for SMS dispatch & emergency responder verification.</span>
              </div>
            </>
          )}

          <div className="form-group">
            <label htmlFor="auth-email">Email Address</label>
            <div className="input-wrapper">
              <Mail size={18} className="field-icon" />
              <input
                id="auth-email"
                type="email"
                placeholder="name@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="auth-password">Password</label>
            <div className="input-wrapper">
              <Lock size={18} className="field-icon" />
              <input
                id="auth-password"
                type="password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {mode === 'register' && (
              <span className="field-help">Secured with Argon2id cryptographic hashing.</span>
            )}
          </div>

          <button 
            type="submit" 
            id="btn-auth-submit"
            className="btn-submit"
            disabled={submitting}
          >
            {submitting ? (
              <>
                <Loader2 size={18} className="spin-icon" />
                <span>Processing Securely...</span>
              </>
            ) : (
              <>
                <span>{mode === 'login' ? 'Sign In to Portal' : 'Create Protected Account'}</span>
                <ArrowRight size={18} />
              </>
            )}
          </button>
        </form>

        <div className="modal-footer-note">
          <CheckCircle2 size={14} className="text-emerald" />
          <span>End-to-end encrypted connection with PostgreSQL isolated tenant storage.</span>
        </div>
      </div>
    </div>
  );
};
