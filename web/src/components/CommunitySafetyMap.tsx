import React, { useState, useEffect, useCallback, useRef } from 'react';
import L from 'leaflet';
import { api } from '../api/client';
import type { SafetyReport, SafetyReportCreatePayload } from '../api/client';
import {
  MapPin,
  ShieldAlert,
  AlertTriangle,
  Building,
  PlusCircle,
  ThumbsUp,
  Filter,
  CheckCircle,
  Crosshair,
  Clock
} from 'lucide-react';

interface CommunitySafetyMapProps {
  token: string;
}

// Category visual themes
const getCategoryTheme = (category: string) => {
  switch (category) {
    case 'safe_haven':
    case 'police_booth':
    case 'hospital':
      return {
        bg: '#ecfdf5',
        border: '#a7f3d0',
        text: '#065f46',
        pinColor: '#059669',
        badge: 'Safe Haven Sanctuary',
        icon: Building,
      };
    case 'harassment_hotspot':
      return {
        bg: '#fff1f2',
        border: '#fecdd3',
        text: '#9f1239',
        pinColor: '#e11d48',
        badge: 'High Danger Area',
        icon: ShieldAlert,
      };
    case 'poor_lighting':
    case 'isolated_route':
    default:
      return {
        bg: '#fffbeb',
        border: '#fde68a',
        text: '#92400e',
        pinColor: '#d97706',
        badge: 'Hazard Advisory',
        icon: AlertTriangle,
      };
  }
};

const createZoneMarkerIcon = (isSafeHaven: boolean) => {
  const color = isSafeHaven ? '#059669' : '#e11d48';
  return L.divIcon({
    className: 'zone-marker-pin',
    html: `
      <div style="position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center;">
        <div style="width: 26px; height: 26px; border-radius: 50%; background: ${color}; border: 3px solid #ffffff; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
          <span style="color: #ffffff; font-size: 13px; font-weight: 800;">${isSafeHaven ? '🛡️' : '⚠️'}</span>
        </div>
      </div>
    `,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });
};

export const CommunitySafetyMap: React.FC<CommunitySafetyMapProps> = ({ token }) => {
  const [reports, setReports] = useState<SafetyReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Filter and Query States
  const [radiusKm, setRadiusKm] = useState<number>(15);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [currentCoords, setCurrentCoords] = useState<{ lat: number; lng: number } | null>(null);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState<SafetyReportCreatePayload>({
    title: '',
    description: '',
    category: 'harassment_hotspot',
    severity_level: 4,
    latitude: 12.9716,
    longitude: 77.5946,
    radius_meters: 250,
  });

  // Leaflet Map Refs
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const radiusCircleRef = useRef<L.Circle | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);

  // Get User Current Location
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lng = pos.coords.longitude;
          setCurrentCoords({ lat, lng });
          setFormData((prev: SafetyReportCreatePayload) => ({ ...prev, latitude: lat, longitude: lng }));
          if (mapInstanceRef.current) {
            mapInstanceRef.current.setView([lat, lng], 13);
          }
        },
        () => {
          setCurrentCoords({ lat: 12.9716, lng: 77.5946 });
        }
      );
    } else {
      setCurrentCoords({ lat: 12.9716, lng: 77.5946 });
    }
  }, []);

  // Fetch Reports from Backend
  const loadReports = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const lat = currentCoords ? currentCoords.lat : 12.9716;
      const lng = currentCoords ? currentCoords.lng : 77.5946;
      const categoryParam = selectedCategory === 'all' ? undefined : selectedCategory;

      const data = await api.getSafetyZones(lat, lng, radiusKm, categoryParam);
      setReports(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load community safety map data');
    } finally {
      setLoading(false);
    }
  }, [currentCoords, radiusKm, selectedCategory]);

  useEffect(() => {
    loadReports();
  }, [loadReports]);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    const lat = currentCoords ? currentCoords.lat : 12.9716;
    const lng = currentCoords ? currentCoords.lng : 77.5946;

    const map = L.map(mapContainerRef.current, {
      center: [lat, lng],
      zoom: 12,
      zoomControl: true,
    });

    // CartoDB Voyager tiles
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
      attribution: '&copy; <a href="https://carto.com/">CARTO</a> OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    markersLayerRef.current = L.layerGroup().addTo(map);

    // Click on map to pin a new hazard/sanctuary
    map.on('click', (e: L.LeafletMouseEvent) => {
      setFormData((prev: SafetyReportCreatePayload) => ({
        ...prev,
        latitude: parseFloat(e.latlng.lat.toFixed(5)),
        longitude: parseFloat(e.latlng.lng.toFixed(5)),
      }));
      setIsModalOpen(true);
    });

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update Radius Circle & Markers on Map
  useEffect(() => {
    if (!mapInstanceRef.current || !markersLayerRef.current) return;

    markersLayerRef.current.clearLayers();

    const lat = currentCoords ? currentCoords.lat : 12.9716;
    const lng = currentCoords ? currentCoords.lng : 77.5946;

    // Draw monitored radius circle
    if (radiusCircleRef.current) {
      radiusCircleRef.current.remove();
    }
    radiusCircleRef.current = L.circle([lat, lng], {
      radius: radiusKm * 1000,
      color: '#7c3aed',
      fillColor: '#8b5cf6',
      fillOpacity: 0.08,
      weight: 1.5,
      dashArray: '6, 6',
    }).addTo(mapInstanceRef.current);

    // Plot Zone Reports
    reports.forEach((rep) => {
      const isSafe = rep.severity_level === 1;
      const marker = L.marker([rep.latitude, rep.longitude], {
        icon: createZoneMarkerIcon(isSafe),
      });

      // Also draw hazard radius circle for danger zones
      if (!isSafe && rep.radius_meters) {
        L.circle([rep.latitude, rep.longitude], {
          radius: rep.radius_meters,
          color: '#ef4444',
          fillColor: '#f43f5e',
          fillOpacity: 0.15,
          weight: 1,
        }).addTo(markersLayerRef.current!);
      }

      const popupHtml = `
        <div style="padding: 4px; font-family: sans-serif; min-width: 180px;">
          <div style="font-weight: 800; font-size: 13px; color: ${isSafe ? '#059669' : '#e11d48'}; margin-bottom: 4px;">
            ${isSafe ? '🛡️ SAFE SANCTUARY' : '⚠️ DANGER HAZARD'}
          </div>
          <div style="font-weight: 700; font-size: 13px; color: #0f172a; margin-bottom: 2px;">
            ${rep.title}
          </div>
          <div style="font-size: 12px; color: #475569; margin-bottom: 6px;">
            ${rep.description}
          </div>
          <div style="font-size: 11px; color: #64748b; margin-bottom: 8px;">
            📍 Verified Votes: <strong>${rep.upvotes}</strong>
          </div>
          <button 
            id="btn-upvote-${rep.id}"
            style="width: 100%; background: #7c3aed; color: #ffffff; border: none; padding: 6px; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer;"
            onclick="window.__upvoteZoneReport && window.__upvoteZoneReport('${rep.id}')"
          >
            👍 Verify Report (${rep.upvotes})
          </button>
        </div>
      `;

      marker.bindPopup(popupHtml);
      markersLayerRef.current?.addLayer(marker);
    });
  }, [reports, currentCoords, radiusKm]);

  // Hook global upvote for Leaflet popup
  useEffect(() => {
    (window as any).__upvoteZoneReport = (id: string) => {
      handleUpvote(id);
    };
    return () => {
      delete (window as any).__upvoteZoneReport;
    };
  }, []);

  // Upvote Handler
  const handleUpvote = async (id: string) => {
    try {
      const updated = await api.upvoteSafetyReport(token, id);
      setReports((prev) => prev.map((r) => (r.id === id ? { ...r, upvotes: updated.upvotes } : r)));
      setSuccessMsg('Thank you for community verification!');
      setTimeout(() => setSuccessMsg(null), 3500);
    } catch (err: any) {
      setError(err.message || 'Failed to verify zone');
    }
  };

  // Submit New Report
  const handleSubmitReport = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await api.submitSafetyReport(token, formData);
      setSuccessMsg('Safety report registered & pinned to live map!');
      setIsModalOpen(false);
      setFormData({
        title: '',
        description: '',
        category: 'harassment_hotspot',
        severity_level: 4,
        latitude: currentCoords ? currentCoords.lat : 12.9716,
        longitude: currentCoords ? currentCoords.lng : 77.5946,
        radius_meters: 250,
      });
      await loadReports();
      setTimeout(() => setSuccessMsg(null), 4000);
    } catch (err: any) {
      setError(err.message || 'Failed to record report');
    }
  };

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Top Controls Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          padding: '1.4rem 1.75rem',
          background: '#ffffff',
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border-subtle)',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
            <span style={{ fontSize: '0.74rem', fontWeight: 700, padding: '0.2rem 0.6rem', borderRadius: 'var(--radius-full)', background: '#ede9fe', color: '#7c3aed' }}>
              COMMUNITY SENTINEL
            </span>
          </div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <MapPin style={{ color: '#7c3aed' }} /> Community Safety & Danger Zones Map
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '0.2rem' }}>
            Geospatial hazard telemetry, verified safe haven sanctuaries, and collective vigilance. Click anywhere on the map to pin a hazard.
          </p>
        </div>

        <button
          id="btn-open-report-zone"
          onClick={() => setIsModalOpen(true)}
          style={{
            background: 'linear-gradient(135deg, #7c3aed 0%, #ec4899 100%)',
            color: '#fff',
            border: 'none',
            borderRadius: 'var(--radius-md)',
            padding: '0.75rem 1.4rem',
            fontWeight: 700,
            fontSize: '0.92rem',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            boxShadow: '0 8px 20px rgba(124, 58, 237, 0.3)',
          }}
        >
          <PlusCircle size={18} /> Report Zone / Sanctuary
        </button>
      </div>

      {error && (
        <div style={{ padding: '0.85rem 1.25rem', borderRadius: 'var(--radius-md)', background: '#fff1f2', border: '1px solid #fecdd3', color: '#9f1239', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600 }}>
          <AlertTriangle size={18} /> {error}
        </div>
      )}

      {successMsg && (
        <div style={{ padding: '0.85rem 1.25rem', borderRadius: 'var(--radius-md)', background: '#ecfdf5', border: '1px solid #a7f3d0', color: '#065f46', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600 }}>
          <CheckCircle size={18} /> {successMsg}
        </div>
      )}

      {/* Filter and Radius Bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          padding: '1rem 1.4rem',
          background: '#ffffff',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border-subtle)',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
            <Filter size={15} /> Filter:
          </span>
          {['all', 'poor_lighting', 'harassment_hotspot', 'isolated_route', 'safe_haven', 'police_booth', 'hospital'].map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              style={{
                background: selectedCategory === cat ? 'rgba(124, 58, 237, 0.12)' : '#f8fafc',
                border: selectedCategory === cat ? '1.5px solid #7c3aed' : '1px solid var(--border-subtle)',
                color: selectedCategory === cat ? '#7c3aed' : 'var(--text-secondary)',
                padding: '0.4rem 0.85rem',
                borderRadius: 'var(--radius-full)',
                fontSize: '0.78rem',
                fontWeight: 600,
                cursor: 'pointer',
                textTransform: 'capitalize',
                transition: 'var(--transition-smooth)',
              }}
            >
              {cat.replace('_', ' ')}
            </button>
          ))}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Monitoring Radius:</span>
          <select
            value={radiusKm}
            onChange={(e) => setRadiusKm(Number(e.target.value))}
            style={{
              background: '#ffffff',
              border: '1.5px solid #e2e8f0',
              borderRadius: 'var(--radius-md)',
              color: 'var(--text-primary)',
              padding: '0.45rem 0.85rem',
              fontSize: '0.88rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            <option value={2}>2 km (Local neighborhood)</option>
            <option value={5}>5 km (Immediate ward)</option>
            <option value={15}>15 km (City zone)</option>
            <option value={30}>30 km (Metropolitan)</option>
            <option value={50}>50 km (Regional)</option>
          </select>
        </div>
      </div>

      {/* Interactive Leaflet Map for Community Safety */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border-subtle)',
          padding: '1.25rem',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
          <span style={{ fontSize: '0.88rem', fontWeight: 700, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <Crosshair size={16} style={{ color: '#7c3aed' }} /> Interactive Map View (Click anywhere on the map to pin a hazard)
          </span>
          <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
            Showing {reports.length} locations within {radiusKm} km
          </span>
        </div>

        <div
          ref={mapContainerRef}
          style={{
            height: '460px',
            width: '100%',
            borderRadius: 'var(--radius-md)',
            overflow: 'hidden',
            border: '1px solid var(--border-subtle)',
            cursor: 'crosshair',
          }}
        />
      </div>

      {/* Safety Reports Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '1.25rem' }}>
        {loading ? (
          <div style={{ color: 'var(--text-muted)', padding: '2rem', textAlign: 'center', gridColumn: '1 / -1' }}>
            Scanning surrounding safety zones...
          </div>
        ) : reports.length === 0 ? (
          <div
            style={{
              padding: '3rem',
              textAlign: 'center',
              background: '#ffffff',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border-subtle)',
              color: 'var(--text-secondary)',
              gridColumn: '1 / -1',
              boxShadow: 'var(--shadow-sm)'
            }}
          >
            <CheckCircle size={40} style={{ color: '#059669', margin: '0 auto 0.85rem' }} />
            <p style={{ fontWeight: 700, fontSize: '1.15rem', color: 'var(--text-primary)' }}>No Danger Zones Reported in Radius</p>
            <p style={{ fontSize: '0.92rem' }}>Your current surroundings ({radiusKm} km) have no recorded danger alerts.</p>
          </div>
        ) : (
          reports.map((report) => {
            const theme = getCategoryTheme(report.category);
            const IconComp = theme.icon;

            return (
              <div
                key={report.id}
                style={{
                  background: '#ffffff',
                  border: `1.5px solid ${theme.border}`,
                  borderRadius: 'var(--radius-md)',
                  padding: '1.35rem',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  boxShadow: 'var(--shadow-sm)',
                  transition: 'var(--transition-smooth)',
                }}
              >
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                    <span
                      style={{
                        background: theme.bg,
                        color: theme.text,
                        fontSize: '0.74rem',
                        fontWeight: 700,
                        padding: '0.25rem 0.65rem',
                        borderRadius: 'var(--radius-full)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.35rem',
                      }}
                    >
                      <IconComp size={14} /> {theme.badge}
                    </span>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <Clock size={12} /> {new Date(report.created_at).toLocaleDateString()}
                    </span>
                  </div>

                  <h4 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.4rem' }}>
                    {report.title}
                  </h4>
                  <p style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '1rem' }}>
                    {report.description}
                  </p>
                </div>

                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    borderTop: '1px solid var(--border-subtle)',
                    paddingTop: '0.85rem',
                  }}
                >
                  <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                    📍 {report.latitude.toFixed(4)}°N, {report.longitude.toFixed(4)}°E
                  </span>

                  <button
                    onClick={() => handleUpvote(report.id)}
                    style={{
                      background: '#f8fafc',
                      border: '1px solid var(--border-subtle)',
                      borderRadius: 'var(--radius-md)',
                      color: 'var(--text-primary)',
                      padding: '0.45rem 0.85rem',
                      fontSize: '0.82rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                      transition: 'var(--transition-smooth)',
                    }}
                  >
                    <ThumbsUp size={14} style={{ color: '#7c3aed' }} /> Verify ({report.upvotes})
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Report Modal */}
      {isModalOpen && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <button className="modal-close-btn" onClick={() => setIsModalOpen(false)}>✕</button>
            <h3 className="modal-title">Pin Zone / Sanctuary</h3>
            <p className="modal-subtitle">Contribute verified safety telemetry to protect fellow women.</p>

            <form onSubmit={handleSubmitReport} className="auth-form">
              <div className="form-group">
                <label className="form-label">Zone Title / Identifier</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Unlit Underpass or 24/7 Police Help Desk"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="form-input"
                  style={{ paddingLeft: '1rem' }}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Detailed Description</label>
                <textarea
                  required
                  rows={3}
                  placeholder="Describe lighting, foot traffic, emergency phone availability, or safety conditions..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="form-input"
                  style={{ paddingLeft: '1rem', resize: 'vertical' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
                <div className="form-group">
                  <label className="form-label">Category</label>
                  <select
                    value={formData.category}
                    onChange={(e) => {
                      const cat = e.target.value;
                      const isSafe = ['safe_haven', 'police_booth', 'hospital'].includes(cat);
                      setFormData({
                        ...formData,
                        category: cat,
                        severity_level: isSafe ? 1 : 4,
                      });
                    }}
                    className="form-input"
                    style={{ paddingLeft: '1rem' }}
                  >
                    <option value="harassment_hotspot">Harassment Hotspot</option>
                    <option value="poor_lighting">Poor Lighting</option>
                    <option value="isolated_route">Isolated Route</option>
                    <option value="safe_haven">Safe Haven Sanctuary</option>
                    <option value="police_booth">24/7 Police Help Booth</option>
                    <option value="hospital">Hospital Emergency Desk</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Perimeter Radius (m)</label>
                  <input
                    type="number"
                    min={50}
                    max={2000}
                    value={formData.radius_meters}
                    onChange={(e) => setFormData({ ...formData, radius_meters: Number(e.target.value) })}
                    className="form-input"
                    style={{ paddingLeft: '1rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
                <div className="form-group">
                  <label className="form-label">Latitude</label>
                  <input
                    type="number"
                    step="0.0001"
                    required
                    value={formData.latitude}
                    onChange={(e) => setFormData({ ...formData, latitude: Number(e.target.value) })}
                    className="form-input"
                    style={{ paddingLeft: '1rem' }}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Longitude</label>
                  <input
                    type="number"
                    step="0.0001"
                    required
                    value={formData.longitude}
                    onChange={(e) => setFormData({ ...formData, longitude: Number(e.target.value) })}
                    className="form-input"
                    style={{ paddingLeft: '1rem' }}
                  />
                </div>
              </div>

              <button type="submit" className="btn-primary" style={{ marginTop: '0.85rem', width: '100%', padding: '0.85rem' }}>
                Pin Location to Community Safety Map
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
