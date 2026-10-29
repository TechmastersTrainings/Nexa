import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../api/client';
import type { SafetyReport } from '../api/client';
import {
  Map,
  Shield,
  AlertTriangle,
  PlusCircle,
  ThumbsUp,
  MapPin,
  ExternalLink,
  Filter,
  CheckCircle,
} from 'lucide-react';

interface CommunitySafetyMapProps {
  token: string;
}

export const CommunitySafetyMap: React.FC<CommunitySafetyMapProps> = ({ token }) => {
  const [reports, setReports] = useState<SafetyReport[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [userLat, setUserLat] = useState<number>(12.9716);
  const [userLng, setUserLng] = useState<number>(77.5946);
  const [radiusKm, setRadiusKm] = useState<number>(15);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // New report form state
  const [formTitle, setFormTitle] = useState('');
  const [formDesc, setFormDesc] = useState('');
  const [formCategory, setFormCategory] = useState('poor_lighting');
  const [formSeverity, setFormSeverity] = useState(3);
  const [formRadius, setFormRadius] = useState(150);

  // Fetch user's geolocation on mount
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setUserLat(pos.coords.latitude);
          setUserLng(pos.coords.longitude);
        },
        () => {
          // Defaults to Bangalore MG road
        }
      );
    }
  }, []);

  const fetchZones = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const cat = selectedCategory === 'all' ? undefined : selectedCategory;
      const data = await api.getSafetyZones(userLat, userLng, radiusKm, cat);
      setReports(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load safety zones');
    } finally {
      setLoading(false);
    }
  }, [userLat, userLng, radiusKm, selectedCategory]);

  useEffect(() => {
    fetchZones();
  }, [fetchZones]);

  const handleUpvote = async (reportId: string) => {
    try {
      await api.upvoteSafetyReport(token, reportId);
      setReports((prev) =>
        prev.map((r) => (r.id === reportId ? { ...r, upvotes: r.upvotes + 1 } : r))
      );
    } catch (err: any) {
      setError(err.message || 'Upvote failed');
    }
  };

  const handleCreateReport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim()) return;

    try {
      setSubmitting(true);
      await api.submitSafetyReport(token, {
        title: formTitle.trim(),
        description: formDesc.trim() || undefined,
        category: formCategory,
        severity_level: formSeverity,
        latitude: userLat,
        longitude: userLng,
        radius_meters: formRadius,
      });
      setIsModalOpen(false);
      setFormTitle('');
      setFormDesc('');
      await fetchZones();
    } catch (err: any) {
      setError(err.message || 'Failed to create report');
    } finally {
      setSubmitting(false);
    }
  };

  const getCategoryTheme = (cat: string) => {
    switch (cat) {
      case 'police_booth':
      case 'hospital':
      case 'safe_haven':
        return {
          bg: 'rgba(16, 185, 129, 0.15)',
          text: '#34d399',
          border: 'rgba(16, 185, 129, 0.4)',
          icon: Shield,
        };
      case 'poor_lighting':
        return {
          bg: 'rgba(245, 158, 11, 0.15)',
          text: '#fbbf24',
          border: 'rgba(245, 158, 11, 0.4)',
          icon: AlertTriangle,
        };
      case 'harassment_hotspot':
      case 'isolated_route':
        return {
          bg: 'rgba(239, 68, 68, 0.15)',
          text: '#f87171',
          border: 'rgba(239, 68, 68, 0.4)',
          icon: AlertTriangle,
        };
      default:
        return {
          bg: 'rgba(99, 102, 241, 0.15)',
          text: '#a5b4fc',
          border: 'rgba(99, 102, 241, 0.4)',
          icon: MapPin,
        };
    }
  };

  return (
    <div
      style={{
        marginTop: '2rem',
        background: 'rgba(255, 255, 255, 0.03)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        borderRadius: '18px',
        padding: '1.8rem',
      }}
    >
      {/* Header bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          marginBottom: '1.4rem',
        }}
      >
        <div>
          <h3 style={{ fontSize: '1.3rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <Map style={{ color: '#38bdf8' }} /> Phase 8: Community Safety Map & Danger Zones
          </h3>
          <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '0.2rem' }}>
            Geospatial hazard telemetry, verified safe haven sanctuaries, and collective vigilance.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          style={{
            background: 'linear-gradient(135deg, #0ea5e9, #6366f1)',
            color: '#fff',
            border: 'none',
            borderRadius: '10px',
            padding: '0.6rem 1.2rem',
            fontWeight: 700,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            boxShadow: '0 0 15px rgba(14, 165, 233, 0.4)',
          }}
        >
          <PlusCircle size={18} /> Report Zone / Sanctuary
        </button>
      </div>

      {error && (
        <div style={{ padding: '0.8rem', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.15)', border: '1px solid rgba(239, 68, 68, 0.3)', color: '#f87171', marginBottom: '1rem' }}>
          {error}
        </div>
      )}

      {/* Filter and Radius controls */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          marginBottom: '1.2rem',
          padding: '1rem',
          background: 'rgba(15, 23, 42, 0.4)',
          borderRadius: '12px',
          border: '1px solid rgba(255, 255, 255, 0.05)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.85rem', color: '#94a3b8', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
            <Filter size={14} /> Filter:
          </span>
          {['all', 'poor_lighting', 'harassment_hotspot', 'isolated_route', 'safe_haven', 'police_booth', 'hospital'].map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              style={{
                background: selectedCategory === cat ? 'rgba(56, 189, 248, 0.25)' : 'rgba(255, 255, 255, 0.04)',
                border: selectedCategory === cat ? '1px solid #38bdf8' : '1px solid rgba(255, 255, 255, 0.08)',
                color: selectedCategory === cat ? '#38bdf8' : '#cbd5e1',
                padding: '0.35rem 0.7rem',
                borderRadius: '8px',
                fontSize: '0.75rem',
                fontWeight: 600,
                cursor: 'pointer',
                textTransform: 'capitalize',
              }}
            >
              {cat.replace('_', ' ')}
            </button>
          ))}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <span style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Radius:</span>
          <select
            value={radiusKm}
            onChange={(e) => setRadiusKm(Number(e.target.value))}
            style={{
              background: '#0f172a',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '8px',
              color: '#f8fafc',
              padding: '0.4rem 0.6rem',
              fontSize: '0.85rem',
            }}
          >
            <option value={2}>2 km</option>
            <option value={5}>5 km</option>
            <option value={15}>15 km</option>
            <option value={30}>30 km</option>
            <option value={50}>50 km</option>
          </select>
        </div>
      </div>

      {/* Reports Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1rem' }}>
        {loading ? (
          <div style={{ color: '#94a3b8', padding: '2rem', textAlign: 'center', gridColumn: '1 / -1' }}>
            Loading surrounding safety zones...
          </div>
        ) : reports.length === 0 ? (
          <div
            style={{
              padding: '2.5rem',
              textAlign: 'center',
              background: 'rgba(255, 255, 255, 0.02)',
              borderRadius: '16px',
              border: '1px dashed rgba(255, 255, 255, 0.1)',
              color: '#94a3b8',
              gridColumn: '1 / -1',
            }}
          >
            <CheckCircle size={36} style={{ color: '#10b981', margin: '0 auto 0.8rem' }} />
            <p style={{ fontWeight: 600, fontSize: '1.1rem', color: '#f8fafc' }}>No Hazards Reported in Radius</p>
            <p style={{ fontSize: '0.9rem' }}>
              Your current surroundings ({radiusKm} km) have no recorded danger alerts.
            </p>
          </div>
        ) : (
          reports.map((report) => {
            const theme = getCategoryTheme(report.category);
            const IconComp = theme.icon;
            const isSafeHaven = report.severity_level === 1;

            return (
              <div
                key={report.id}
                style={{
                  background: 'rgba(255, 255, 255, 0.02)',
                  border: `1px solid ${theme.border}`,
                  borderRadius: '14px',
                  padding: '1.2rem',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  gap: '0.8rem',
                }}
              >
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
                    <span
                      style={{
                        background: theme.bg,
                        color: theme.text,
                        border: `1px solid ${theme.border}`,
                        padding: '0.2rem 0.6rem',
                        borderRadius: '6px',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.3rem',
                      }}
                    >
                      <IconComp size={12} /> {report.category.replace('_', ' ')}
                    </span>

                    <span style={{ fontSize: '0.75rem', color: '#38bdf8', fontWeight: 600 }}>
                      {report.distance_km !== null ? `${report.distance_km} km away` : ''}
                    </span>
                  </div>

                  <h4 style={{ color: '#f8fafc', fontWeight: 700, fontSize: '1.05rem', marginBottom: '0.3rem' }}>
                    {report.title}
                  </h4>

                  {report.description && (
                    <p style={{ color: '#94a3b8', fontSize: '0.85rem', lineHeight: 1.4, marginBottom: '0.6rem' }}>
                      {report.description}
                    </p>
                  )}

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', fontSize: '0.8rem', color: '#64748b' }}>
                    <span>Severity: {isSafeHaven ? 'Sanctuary (Safe)' : `${report.severity_level}/5 Danger`}</span>
                    <span>•</span>
                    <span>Radius: ~{report.radius_meters}m</span>
                  </div>
                </div>

                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    borderTop: '1px solid rgba(255, 255, 255, 0.06)',
                    paddingTop: '0.6rem',
                  }}
                >
                  <a
                    href={`https://maps.google.com/?q=${report.latitude},${report.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.3rem',
                      color: '#38bdf8',
                      fontSize: '0.8rem',
                      textDecoration: 'none',
                    }}
                  >
                    <ExternalLink size={12} /> View on Map
                  </a>

                  <button
                    onClick={() => handleUpvote(report.id)}
                    style={{
                      background: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                      color: '#cbd5e1',
                      borderRadius: '8px',
                      padding: '0.35rem 0.7rem',
                      fontSize: '0.8rem',
                      fontWeight: 600,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                    }}
                  >
                    <ThumbsUp size={12} /> {report.upvotes}
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Create Modal */}
      {isModalOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.75)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            backdropFilter: 'blur(5px)',
          }}
        >
          <div
            style={{
              background: '#0e131f',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '16px',
              padding: '2rem',
              width: '90%',
              maxWidth: '520px',
            }}
          >
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#f8fafc', marginBottom: '1.2rem' }}>
              Report Safety Hazard or Safe Haven
            </h3>

            <form onSubmit={handleCreateReport} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Title / Identifier
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g., Broken streetlights near north pedestrian bridge"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.6rem 0.8rem',
                    borderRadius: '8px',
                    background: '#090d16',
                    border: '1px solid rgba(255, 255, 255, 0.15)',
                    color: '#f8fafc',
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Category
                </label>
                <select
                  value={formCategory}
                  onChange={(e) => {
                    const val = e.target.value;
                    setFormCategory(val);
                    if (['safe_haven', 'police_booth', 'hospital'].includes(val)) {
                      setFormSeverity(1);
                    } else {
                      setFormSeverity(3);
                    }
                  }}
                  style={{
                    width: '100%',
                    padding: '0.6rem 0.8rem',
                    borderRadius: '8px',
                    background: '#090d16',
                    border: '1px solid rgba(255, 255, 255, 0.15)',
                    color: '#f8fafc',
                  }}
                >
                  <option value="poor_lighting">Poor Lighting</option>
                  <option value="harassment_hotspot">Harassment Hotspot</option>
                  <option value="isolated_route">Isolated / Deserted Route</option>
                  <option value="safe_haven">Safe Haven / 24x7 Store</option>
                  <option value="police_booth">Police Assistance Booth</option>
                  <option value="hospital">Hospital / Emergency Medical Care</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Severity Level (1 = Safe Haven, 5 = Severe Danger)
                </label>
                <input
                  type="range"
                  min="1"
                  max="5"
                  value={formSeverity}
                  onChange={(e) => setFormSeverity(Number(e.target.value))}
                  style={{ width: '100%' }}
                />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: '#64748b' }}>
                  <span>1: Safe Sanctuary</span>
                  <span style={{ color: '#38bdf8', fontWeight: 700 }}>Level: {formSeverity}</span>
                  <span>5: Critical Danger</span>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Zone Radius: ~{formRadius} meters
                </label>
                <input
                  type="range"
                  min="50"
                  max="1000"
                  step="50"
                  value={formRadius}
                  onChange={(e) => setFormRadius(Number(e.target.value))}
                  style={{ width: '100%' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Description (Optional)
                </label>
                <textarea
                  rows={3}
                  placeholder="Details to alert other women and guardians..."
                  value={formDesc}
                  onChange={(e) => setFormDesc(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.6rem 0.8rem',
                    borderRadius: '8px',
                    background: '#090d16',
                    border: '1px solid rgba(255, 255, 255, 0.15)',
                    color: '#f8fafc',
                  }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.8rem', marginTop: '0.5rem' }}>
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  style={{
                    background: 'transparent',
                    border: '1px solid rgba(255, 255, 255, 0.2)',
                    color: '#cbd5e1',
                    borderRadius: '8px',
                    padding: '0.6rem 1.2rem',
                    cursor: 'pointer',
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    background: 'linear-gradient(135deg, #0ea5e9, #6366f1)',
                    border: 'none',
                    color: '#fff',
                    borderRadius: '8px',
                    padding: '0.6rem 1.4rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {submitting ? 'Submitting...' : 'Save & Broadcast'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
