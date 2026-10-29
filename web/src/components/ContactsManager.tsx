import React, { useState, useEffect } from 'react';
import { 
  Users, 
  UserPlus, 
  Trash2, 
  ShieldCheck, 
  AlertCircle, 
  Phone, 
  Loader2, 
  CheckCircle2, 
  KeyRound, 
  X 
} from 'lucide-react';
import { api } from '../api/client';
import type { TrustedContact } from '../api/client';
import { useAuth } from '../context/AuthContext';

export const ContactsManager: React.FC = () => {
  const { token } = useAuth();
  const [contacts, setContacts] = useState<TrustedContact[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Modal / Form state
  const [showAddModal, setShowAddModal] = useState(false);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [relationship, setRelationship] = useState('Family');
  const [priority, setPriority] = useState(1);
  const [submitting, setSubmitting] = useState(false);

  // Verification state
  const [verifyingId, setVerifyingId] = useState<string | null>(null);
  const [verifyCode, setVerifyCode] = useState('');
  const [verifying, setVerifying] = useState(false);

  const fetchContacts = async () => {
    if (!token) return;
    try {
      setLoading(true);
      setError(null);
      const data = await api.getContacts(token);
      setContacts(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load contacts');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContacts();
  }, [token]);

  const handleAddContact = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setError(null);
    setSuccessMsg(null);

    if (!name.trim() || !phone.trim()) {
      setError('Name and phone number are required.');
      return;
    }

    setSubmitting(true);
    try {
      await api.addContact(token, {
        name: name.trim(),
        phone_number: phone.trim(),
        relationship,
        priority_order: priority,
      });
      setSuccessMsg('Emergency contact added successfully.');
      setName('');
      setPhone('');
      setShowAddModal(false);
      await fetchContacts();
    } catch (err: any) {
      setError(err.message || 'Failed to add contact');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteContact = async (contactId: string) => {
    if (!token) return;
    if (!confirm('Are you sure you want to remove this emergency responder?')) return;
    setError(null);
    try {
      await api.deleteContact(token, contactId);
      setSuccessMsg('Responder removed.');
      await fetchContacts();
    } catch (err: any) {
      setError(err.message || 'Failed to delete contact');
    }
  };

  const handleVerifySubmit = async (contactId: string) => {
    if (!token || !verifyCode.trim()) return;
    setVerifying(true);
    setError(null);
    try {
      await api.verifyContact(token, contactId, verifyCode.trim());
      setSuccessMsg('Contact verification confirmed!');
      setVerifyingId(null);
      setVerifyCode('');
      await fetchContacts();
    } catch (err: any) {
      setError(err.message || 'Verification code failed');
    } finally {
      setVerifying(false);
    }
  };

  return (
    <div className="dashboard-card contacts-card">
      <div className="card-header" style={{ justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
          <div className="card-header-icon">
            <Users size={20} className="text-indigo" />
          </div>
          <div>
            <h2 className="card-title">Trusted Responders (Phase 2)</h2>
            <span className="card-caption">Tiered Emergency Dispatch Network</span>
          </div>
        </div>

        <button 
          id="btn-open-add-contact"
          className="btn-primary" 
          style={{ padding: '0.45rem 1rem', fontSize: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
          onClick={() => setShowAddModal(true)}
        >
          <UserPlus size={15} />
          <span>Add Responder</span>
        </button>
      </div>

      {/* Notifications */}
      {error && (
        <div className="auth-error-banner animate-fade-in" style={{ marginBottom: '1rem' }}>
          <AlertCircle size={16} />
          <span>{error}</span>
        </div>
      )}

      {successMsg && (
        <div className="auth-error-banner animate-fade-in" style={{ marginBottom: '1rem', background: 'rgba(16, 185, 129, 0.12)', borderColor: 'rgba(16, 185, 129, 0.35)', color: '#6ee7b7' }}>
          <CheckCircle2 size={16} />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Content */}
      {loading ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
          <Loader2 size={24} className="spin-icon text-indigo" />
        </div>
      ) : contacts.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '2rem 1rem', color: 'var(--text-muted)' }}>
          <Users size={36} style={{ margin: '0 auto 0.75rem', opacity: 0.4 }} />
          <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>No emergency contacts added yet.</p>
          <p style={{ fontSize: '0.78rem' }}>Add up to 5 verified responders to receive automated SOS alerts.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
          {contacts.map((c) => (
            <div 
              key={c.id} 
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '0.85rem 1rem',
                background: 'rgba(255, 255, 255, 0.02)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-md)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
                <div 
                  style={{
                    width: 34,
                    height: 34,
                    borderRadius: '50%',
                    background: 'rgba(99, 102, 241, 0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#a5b4fc',
                    fontWeight: 700,
                    fontSize: '0.9rem',
                  }}
                >
                  {c.name[0].toUpperCase()}
                </div>

                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontWeight: 700, color: 'var(--text-primary)', fontSize: '0.92rem' }}>
                      {c.name}
                    </span>
                    <span 
                      style={{ 
                        fontSize: '0.7rem', 
                        padding: '0.1rem 0.45rem', 
                        borderRadius: 4, 
                        background: 'rgba(255,255,255,0.06)',
                        color: 'var(--text-muted)'
                      }}
                    >
                      {c.relationship}
                    </span>
                    <span 
                      style={{ 
                        fontSize: '0.7rem', 
                        padding: '0.1rem 0.45rem', 
                        borderRadius: 4, 
                        background: c.priority_order === 1 ? 'rgba(244, 63, 94, 0.2)' : 'rgba(99, 102, 241, 0.2)',
                        color: c.priority_order === 1 ? '#fca5a5' : '#c7d2fe',
                        fontWeight: 700,
                      }}
                    >
                      Priority {c.priority_order}
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginTop: '0.2rem' }}>
                    <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
                      <Phone size={12} /> {c.phone_number}
                    </span>
                    <span 
                      className={`status-chip ${c.is_verified ? 'chip-emerald' : 'chip-amber'}`}
                      style={{ fontSize: '0.68rem', padding: '0.1rem 0.45rem' }}
                    >
                      {c.is_verified ? 'Handshake Verified' : 'Pending Verification'}
                    </span>
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                {!c.is_verified && (
                  <button
                    className="btn-ghost"
                    style={{ fontSize: '0.75rem', padding: '0.35rem 0.65rem', border: '1px solid rgba(245, 158, 11, 0.3)', color: '#fcd34d' }}
                    onClick={() => setVerifyingId(c.id)}
                    title="Enter verification PIN"
                  >
                    <KeyRound size={13} style={{ display: 'inline', marginRight: 4 }} />
                    Verify
                  </button>
                )}

                <button
                  className="btn-ghost"
                  style={{ color: '#f87171', padding: '0.35rem' }}
                  onClick={() => handleDeleteContact(c.id)}
                  title="Remove responder"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Verify Code Modal Dialog */}
      {verifyingId && (
        <div className="modal-backdrop" onClick={() => setVerifyingId(null)}>
          <div className="modal-card" style={{ maxWidth: 380, padding: '1.75rem' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Confirm Responder Handshake</h3>
              <button className="modal-close-btn" onClick={() => setVerifyingId(null)}><X size={16} /></button>
            </div>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginBottom: '1rem' }}>
              Enter the 6-digit verification PIN assigned to this responder contact.
            </p>
            <input 
              type="text" 
              placeholder="e.g. 849201" 
              value={verifyCode} 
              onChange={(e) => setVerifyCode(e.target.value)}
              maxLength={6}
              style={{
                width: '100%',
                background: 'var(--bg-input)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-md)',
                padding: '0.75rem',
                color: 'white',
                fontSize: '1.1rem',
                letterSpacing: '0.2em',
                textAlign: 'center',
                marginBottom: '1rem'
              }}
            />
            <button 
              className="btn-primary" 
              style={{ width: '100%' }}
              onClick={() => handleVerifySubmit(verifyingId)}
              disabled={verifying || verifyCode.trim().length < 4}
            >
              {verifying ? 'Validating...' : 'Confirm Verification'}
            </button>
          </div>
        </div>
      )}

      {/* Add Contact Modal Dialog */}
      {showAddModal && (
        <div className="modal-backdrop" onClick={() => setShowAddModal(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <button className="modal-close-btn" onClick={() => setShowAddModal(false)}><X size={16} /></button>
            <div className="modal-header">
              <div className="modal-icon-badge">
                <ShieldCheck size={24} className="icon-shield-accent" />
              </div>
              <h2 className="modal-title">Add Emergency Contact</h2>
              <p className="modal-desc">Configure a trusted person to receive priority alerts and location telemetries.</p>
            </div>

            <form onSubmit={handleAddContact} className="auth-form">
              <div className="form-group">
                <label>Contact Full Name</label>
                <input 
                  type="text" 
                  placeholder="e.g. Maya Lin" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)} 
                  required 
                  style={{
                    background: 'var(--bg-input)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-md)',
                    padding: '0.75rem',
                    color: 'white'
                  }}
                />
              </div>

              <div className="form-group">
                <label>Phone Number (with Country Code)</label>
                <input 
                  type="tel" 
                  placeholder="+919876543210" 
                  value={phone} 
                  onChange={(e) => setPhone(e.target.value)} 
                  required 
                  style={{
                    background: 'var(--bg-input)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-md)',
                    padding: '0.75rem',
                    color: 'white'
                  }}
                />
              </div>

              <div className="form-group">
                <label>Relationship</label>
                <select
                  value={relationship}
                  onChange={(e) => setRelationship(e.target.value)}
                  style={{
                    background: 'var(--bg-input)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-md)',
                    padding: '0.75rem',
                    color: 'white'
                  }}
                >
                  <option value="Family">Family</option>
                  <option value="Parent">Parent</option>
                  <option value="Spouse">Spouse</option>
                  <option value="Sibling">Sibling</option>
                  <option value="Friend">Friend</option>
                  <option value="Guardian">Guardian</option>
                </select>
              </div>

              <div className="form-group">
                <label>Dispatch Escalation Priority</label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(Number(e.target.value))}
                  style={{
                    background: 'var(--bg-input)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-md)',
                    padding: '0.75rem',
                    color: 'white'
                  }}
                >
                  <option value={1}>Priority 1 (First responder contacted immediately)</option>
                  <option value={2}>Priority 2 (Contacted if Priority 1 unreachable)</option>
                  <option value={3}>Priority 3 (Broadcast backup responder)</option>
                </select>
              </div>

              <button type="submit" className="btn-submit" disabled={submitting}>
                {submitting ? 'Registering Responder...' : 'Save Emergency Responder'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
