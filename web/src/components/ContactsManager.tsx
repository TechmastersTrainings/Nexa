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
            <h2 className="card-title">Trusted Emergency Responders</h2>
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
                padding: '1rem 1.25rem',
                background: '#f8fafc',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-md)',
                boxShadow: 'var(--shadow-sm)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
                <div 
                  style={{
                    width: 38,
                    height: 38,
                    borderRadius: '50%',
                    background: 'rgba(124, 58, 237, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#7c3aed',
                    fontWeight: 700,
                    fontSize: '0.95rem',
                  }}
                >
                  {c.name[0].toUpperCase()}
                </div>

                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontWeight: 700, color: 'var(--text-primary)', fontSize: '0.95rem' }}>
                      {c.name}
                    </span>
                    <span 
                      style={{ 
                        fontSize: '0.72rem', 
                        padding: '0.15rem 0.5rem', 
                        borderRadius: 6, 
                        background: '#ffffff',
                        border: '1px solid var(--border-subtle)',
                        color: 'var(--text-muted)'
                      }}
                    >
                      {c.relationship}
                    </span>
                    <span 
                      style={{ 
                        fontSize: '0.72rem', 
                        padding: '0.15rem 0.5rem', 
                        borderRadius: 6, 
                        background: c.priority_order === 1 ? '#fee2e2' : '#ede9fe',
                        color: c.priority_order === 1 ? '#b91c1c' : '#6d28d9',
                        fontWeight: 700,
                      }}
                    >
                      Priority {c.priority_order}
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginTop: '0.2rem' }}>
                    <span style={{ fontSize: '0.84rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
                      <Phone size={13} style={{ color: '#7c3aed' }} /> {c.phone_number}
                    </span>
                    <span 
                      className={`status-chip ${c.is_verified ? 'chip-emerald' : 'chip-amber'}`}
                      style={{ fontSize: '0.72rem', padding: '0.15rem 0.55rem' }}
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
                    style={{ fontSize: '0.78rem', padding: '0.4rem 0.75rem', border: '1px solid #fde68a', background: '#fffbeb', color: '#b45309', fontWeight: 700 }}
                    onClick={() => setVerifyingId(c.id)}
                    title="Enter verification PIN"
                  >
                    <KeyRound size={13} style={{ display: 'inline', marginRight: 4 }} />
                    Verify PIN
                  </button>
                )}

                <button
                  className="btn-ghost"
                  style={{ color: '#e11d48', padding: '0.45rem', borderRadius: 'var(--radius-md)' }}
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
          <div className="modal-card" style={{ maxWidth: 400, padding: '2rem' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>Confirm Responder Handshake</h3>
              <button className="modal-close-btn" onClick={() => setVerifyingId(null)}><X size={16} /></button>
            </div>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', marginBottom: '1.25rem' }}>
              Enter the 6-digit verification PIN assigned to this responder contact.
            </p>
            <input 
              type="text" 
              placeholder="e.g. 123456" 
              value={verifyCode} 
              onChange={(e) => setVerifyCode(e.target.value)}
              maxLength={6}
              style={{
                width: '100%',
                background: '#ffffff',
                border: '1.5px solid #e2e8f0',
                borderRadius: 'var(--radius-md)',
                padding: '0.85rem',
                color: 'var(--text-primary)',
                fontSize: '1.3rem',
                letterSpacing: '0.25em',
                textAlign: 'center',
                marginBottom: '1.25rem',
                fontWeight: 700,
              }}
            />
            <button 
              className="btn-primary" 
              style={{ width: '100%', padding: '0.85rem' }}
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
