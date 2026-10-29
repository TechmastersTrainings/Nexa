import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../api/client';
import type { IncidentRecord, AlertLog } from '../api/client';
import {
  AlertTriangle,
  Radio,
  MapPin,
  Battery,
  PhoneCall,
  CheckCircle,
  Clock,
  RefreshCw,
  Send,
  ExternalLink,
  ShieldAlert,
} from 'lucide-react';

interface IncidentsLiveMapProps {
  token: string;
}

export const IncidentsLiveMap: React.FC<IncidentsLiveMapProps> = ({ token }) => {
  const [incidents, setIncidents] = useState<IncidentRecord[]>([]);
  const [alerts, setAlerts] = useState<AlertLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [dispatchingId, setDispatchingId] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [activeTab, setActiveTab] = useState<'incidents' | 'alerts'>('incidents');

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [incidentsData, alertsData] = await Promise.all([
        api.getIncidents(token),
        api.getAlertHistory(token),
      ]);
      setIncidents(incidentsData);
      setAlerts(alertsData);
      setFeedback(null);
    } catch (err: any) {
      setFeedback({ message: err.message || 'Failed to fetch incident telemetry', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 10000);
    return () => clearInterval(interval);
  }, [loadData]);

  const handleDispatchAlert = async (incidentId: string, alertType: 'sms' | 'voice') => {
    try {
      setDispatchingId(incidentId);
      const result = await api.dispatchAlerts(token, incidentId, alertType);
      setFeedback({
        message: `Emergency SOS broadcast sent to ${result.dispatched_count} verified contacts via ${alertType.toUpperCase()}!`,
        type: 'success',
      });
      await loadData();
    } catch (err: any) {
      setFeedback({ message: err.message || 'Alert dispatch failed', type: 'error' });
    } finally {
      setDispatchingId(null);
    }
  };

  const handleWebSosTrigger = async () => {
    if (!navigator.geolocation) {
      triggerWithFallback();
      return;
    }

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const newInc = await api.recordIncident(token, {
            client_incident_id: `web-sos-${Date.now()}`,
            trigger_type: 'web_portal_panic',
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude,
            accuracy_meters: pos.coords.accuracy,
            local_created_at: new Date().toISOString(),
          });
          // Auto-dispatch alert
          await api.dispatchAlerts(token, newInc.id, 'sms');
          setFeedback({
            message: 'Web SOS Distress Incident triggered & alerts dispatched to trusted contacts!',
            type: 'success',
          });
          await loadData();
        } catch (e: any) {
          setFeedback({ message: e.message || 'Failed to trigger Web SOS', type: 'error' });
        }
      },
      () => {
        triggerWithFallback();
      },
      { timeout: 7000 }
    );
  };

  const triggerWithFallback = async () => {
    try {
      const newInc = await api.recordIncident(token, {
        client_incident_id: `web-sos-${Date.now()}`,
        trigger_type: 'web_portal_panic',
        location_unavailable: true,
        local_created_at: new Date().toISOString(),
      });
      await api.dispatchAlerts(token, newInc.id, 'sms');
      setFeedback({
        message: 'Web SOS Triggered without GPS coordinates. Emergency contacts notified!',
        type: 'success',
      });
      await loadData();
    } catch (e: any) {
      setFeedback({ message: e.message || 'Failed to trigger Web SOS', type: 'error' });
    }
  };

  return (
    <div style={{ marginTop: '2.5rem' }}>
      {/* Header bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}
      >
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <Radio style={{ color: '#00f2fe' }} /> Live Emergency Monitor & Incident Telemetry
          </h2>
          <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginTop: '0.2rem' }}>
            Real-time GPS telemetry, safe word triggers, and telecom alert broadcast logs.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center' }}>
          <button
            onClick={() => handleWebSosTrigger()}
            style={{
              background: 'linear-gradient(135deg, #ef4444 0%, #b91c1c 100%)',
              color: '#ffffff',
              border: 'none',
              borderRadius: '10px',
              padding: '0.6rem 1.2rem',
              fontWeight: 700,
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              cursor: 'pointer',
              boxShadow: '0 0 15px rgba(239, 68, 68, 0.4)',
            }}
          >
            <ShieldAlert size={18} /> Trigger SOS Broadcast
          </button>

          <button
            onClick={loadData}
            disabled={loading}
            style={{
              background: 'rgba(255, 255, 255, 0.05)',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              borderRadius: '10px',
              color: '#f8fafc',
              padding: '0.6rem 0.9rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
            }}
          >
            <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
          </button>
        </div>
      </div>

      {feedback && (
        <div
          style={{
            padding: '0.8rem 1.2rem',
            borderRadius: '10px',
            marginBottom: '1.2rem',
            background:
              feedback.type === 'success'
                ? 'rgba(16, 185, 129, 0.15)'
                : 'rgba(239, 68, 68, 0.15)',
            border:
              feedback.type === 'success'
                ? '1px solid rgba(16, 185, 129, 0.4)'
                : '1px solid rgba(239, 68, 68, 0.4)',
            color: feedback.type === 'success' ? '#34d399' : '#f87171',
            display: 'flex',
            alignItems: 'center',
            gap: '0.6rem',
          }}
        >
          {feedback.type === 'success' ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
          <span>{feedback.message}</span>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '0.6rem', marginBottom: '1.2rem', borderBottom: '1px solid rgba(255, 255, 255, 0.1)', paddingBottom: '0.5rem' }}>
        <button
          onClick={() => setActiveTab('incidents')}
          style={{
            background: activeTab === 'incidents' ? 'rgba(79, 70, 229, 0.25)' : 'transparent',
            border: activeTab === 'incidents' ? '1px solid rgba(99, 102, 241, 0.5)' : 'none',
            color: activeTab === 'incidents' ? '#c7d2fe' : '#94a3b8',
            borderRadius: '8px',
            padding: '0.5rem 1rem',
            cursor: 'pointer',
            fontWeight: 600,
          }}
        >
          Incidents ({incidents.length})
        </button>
        <button
          onClick={() => setActiveTab('alerts')}
          style={{
            background: activeTab === 'alerts' ? 'rgba(79, 70, 229, 0.25)' : 'transparent',
            border: activeTab === 'alerts' ? '1px solid rgba(99, 102, 241, 0.5)' : 'none',
            color: activeTab === 'alerts' ? '#c7d2fe' : '#94a3b8',
            borderRadius: '8px',
            padding: '0.5rem 1rem',
            cursor: 'pointer',
            fontWeight: 600,
          }}
        >
          Dispatched Emergency Alerts ({alerts.length})
        </button>
      </div>

      {/* Tab Content: Incidents */}
      {activeTab === 'incidents' && (
        <div style={{ display: 'grid', gap: '1rem' }}>
          {incidents.length === 0 ? (
            <div
              style={{
                padding: '2.5rem',
                textAlign: 'center',
                background: 'rgba(255, 255, 255, 0.02)',
                borderRadius: '16px',
                border: '1px dashed rgba(255, 255, 255, 0.1)',
                color: '#94a3b8',
              }}
            >
              <CheckCircle size={36} style={{ color: '#10b981', margin: '0 auto 0.8rem' }} />
              <p style={{ fontWeight: 600, fontSize: '1.1rem', color: '#f8fafc' }}>
                All Safe & Protected
              </p>
              <p style={{ fontSize: '0.9rem' }}>No distress incidents recorded in this session.</p>
            </div>
          ) : (
            incidents.map((inc) => (
              <div
                key={inc.id}
                style={{
                  background: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid rgba(255, 255, 255, 0.08)',
                  borderRadius: '14px',
                  padding: '1.2rem',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '1rem',
                }}
              >
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                    <span
                      style={{
                        background: 'rgba(239, 68, 68, 0.2)',
                        color: '#f87171',
                        border: '1px solid rgba(239, 68, 68, 0.3)',
                        borderRadius: '6px',
                        padding: '0.2rem 0.6rem',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                      }}
                    >
                      {inc.trigger_type}
                    </span>
                    <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
                      ID: {inc.client_incident_id.slice(0, 18)}...
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap', marginTop: '0.2rem' }}>
                    {inc.latitude && inc.longitude && !inc.location_unavailable ? (
                      <a
                        href={`https://maps.google.com/?q=${inc.latitude},${inc.longitude}`}
                        target="_blank"
                        rel="noreferrer"
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.3rem',
                          color: '#38bdf8',
                          fontSize: '0.85rem',
                          textDecoration: 'none',
                        }}
                      >
                        <MapPin size={15} /> {inc.latitude.toFixed(5)}, {inc.longitude.toFixed(5)}{' '}
                        <ExternalLink size={12} />
                      </a>
                    ) : (
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', color: '#94a3b8', fontSize: '0.85rem' }}>
                        <MapPin size={15} /> Coordinates Offline
                      </span>
                    )}

                    {inc.battery_level !== null && (
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', color: '#a7f3d0', fontSize: '0.85rem' }}>
                        <Battery size={15} /> {inc.battery_level}%
                      </span>
                    )}

                    <span style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', color: '#94a3b8', fontSize: '0.85rem' }}>
                      <Clock size={14} /> {new Date(inc.local_created_at).toLocaleTimeString()}
                    </span>
                  </div>
                </div>

                {/* Broadcast actions */}
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button
                    onClick={() => handleDispatchAlert(inc.id, 'sms')}
                    disabled={dispatchingId === inc.id}
                    style={{
                      background: 'rgba(99, 102, 241, 0.15)',
                      border: '1px solid rgba(99, 102, 241, 0.4)',
                      borderRadius: '8px',
                      color: '#c7d2fe',
                      padding: '0.45rem 0.8rem',
                      fontSize: '0.85rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                    }}
                  >
                    <Send size={14} /> Broadcast SMS
                  </button>
                  <button
                    onClick={() => handleDispatchAlert(inc.id, 'voice')}
                    disabled={dispatchingId === inc.id}
                    style={{
                      background: 'rgba(234, 179, 8, 0.15)',
                      border: '1px solid rgba(234, 179, 8, 0.4)',
                      borderRadius: '8px',
                      color: '#fef08a',
                      padding: '0.45rem 0.8rem',
                      fontSize: '0.85rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                    }}
                  >
                    <PhoneCall size={14} /> Voice Call
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Tab Content: Alerts */}
      {activeTab === 'alerts' && (
        <div style={{ display: 'grid', gap: '1rem' }}>
          {alerts.length === 0 ? (
            <div
              style={{
                padding: '2.5rem',
                textAlign: 'center',
                background: 'rgba(255, 255, 255, 0.02)',
                borderRadius: '16px',
                border: '1px dashed rgba(255, 255, 255, 0.1)',
                color: '#94a3b8',
              }}
            >
              <Radio size={36} style={{ color: '#6366f1', margin: '0 auto 0.8rem' }} />
              <p style={{ fontWeight: 600, fontSize: '1.1rem', color: '#f8fafc' }}>
                No Dispatched Alerts Yet
              </p>
              <p style={{ fontSize: '0.9rem' }}>
                When an emergency is triggered, SMS and voice broadcasts to your contacts appear here.
              </p>
            </div>
          ) : (
            alerts.map((al) => (
              <div
                key={al.id}
                style={{
                  background: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid rgba(255, 255, 255, 0.08)',
                  borderRadius: '14px',
                  padding: '1.2rem',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.6rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                    <span
                      style={{
                        background:
                          al.delivery_status === 'delivered' || al.delivery_status === 'sent'
                            ? 'rgba(16, 185, 129, 0.2)'
                            : 'rgba(239, 68, 68, 0.2)',
                        color:
                          al.delivery_status === 'delivered' || al.delivery_status === 'sent'
                            ? '#34d399'
                            : '#f87171',
                        borderRadius: '6px',
                        padding: '0.2rem 0.5rem',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                      }}
                    >
                      {al.delivery_status}
                    </span>
                    <span style={{ color: '#f8fafc', fontWeight: 600, fontSize: '0.9rem' }}>
                      To: {al.recipient_phone}
                    </span>
                  </div>
                  <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
                    Provider ID: {al.provider_message_id || 'N/A'}
                  </span>
                </div>
                <p style={{ fontSize: '0.85rem', color: '#cbd5e1', lineHeight: '1.4' }}>
                  {al.message_body}
                </p>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.6rem', fontSize: '0.75rem', color: '#64748b' }}>
                  <span>Gateway: {al.provider}</span>
                  <span>{new Date(al.created_at).toLocaleString()}</span>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
};
