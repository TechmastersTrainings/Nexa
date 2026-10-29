import React, { useState } from 'react';
import { api } from '../api/client';
import type { StressAnalysisResult } from '../api/client';
import {
  Activity,
  Mic,
  ShieldCheck,
  AlertTriangle,
  Play,
  Volume2,
  Lock,
  Sparkles,
} from 'lucide-react';

interface VoiceStressBenchProps {
  token: string;
}

export const VoiceStressBench: React.FC<VoiceStressBenchProps> = ({ token }) => {
  const [result, setResult] = useState<StressAnalysisResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [recording, setRecording] = useState(false);

  // Preset diagnostic acoustic scenarios
  const runPreset = async (type: 'calm' | 'anxious' | 'screaming') => {
    try {
      setLoading(true);
      setError(null);

      let override = {};
      if (type === 'calm') {
        override = {
          rms_energy: 0.08,
          zero_crossing_rate: 0.09,
          high_frequency_ratio: 0.15,
          amplitude_variance: 0.002,
          estimated_pitch_hz: 165.0,
        };
      } else if (type === 'anxious') {
        override = {
          rms_energy: 0.22,
          zero_crossing_rate: 0.28,
          high_frequency_ratio: 0.48,
          amplitude_variance: 0.015,
          estimated_pitch_hz: 240.0,
        };
      } else if (type === 'screaming') {
        override = {
          rms_energy: 0.45,
          zero_crossing_rate: 0.49,
          high_frequency_ratio: 0.88,
          amplitude_variance: 0.065,
          estimated_pitch_hz: 410.0,
        };
      }

      const res = await api.analyzeStress(token, {
        feature_override: override,
      });
      setResult(res);
    } catch (err: any) {
      setError(err.message || 'Analysis failed');
    } finally {
      setLoading(false);
    }
  };

  const recordLiveMicrophone = async () => {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      setError('Microphone access is not supported in this browser.');
      return;
    }

    try {
      setError(null);
      setRecording(true);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      const audioChunks: Blob[] = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) audioChunks.push(e.data);
      };

      mediaRecorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
        const reader = new FileReader();
        reader.onloadend = async () => {
          try {
            const base64Audio = (reader.result as string).split(',')[1];
            setLoading(true);
            const res = await api.analyzeStress(token, {
              raw_audio_base64: base64Audio,
              sample_rate: 16000,
            });
            setResult(res);
          } catch (e: any) {
            setError(e.message || 'Microphone audio analysis failed.');
          } finally {
            setLoading(false);
          }
        };
        reader.readAsDataURL(audioBlob);
      };

      mediaRecorder.start();
      // Record for 2.5 seconds
      setTimeout(() => {
        if (mediaRecorder.state !== 'inactive') {
          mediaRecorder.stop();
          setRecording(false);
        }
      }, 2500);
    } catch (e: any) {
      setRecording(false);
      setError(e.message || 'Microphone permission denied.');
    }
  };

  const getRiskColor = (level: string) => {
    switch (level) {
      case 'CRITICAL_DISTRESS':
        return { bg: 'rgba(239, 68, 68, 0.2)', text: '#f87171', border: 'rgba(239, 68, 68, 0.4)' };
      case 'ELEVATED_STRESS':
        return { bg: 'rgba(245, 158, 11, 0.2)', text: '#fbbf24', border: 'rgba(245, 158, 11, 0.4)' };
      default:
        return { bg: 'rgba(16, 185, 129, 0.2)', text: '#34d399', border: 'rgba(16, 185, 129, 0.4)' };
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.2rem' }}>
        <div>
          <h3 style={{ fontSize: '1.3rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <Activity style={{ color: '#a855f7' }} /> Phase 7: Voice-Stress ML Classification Bench
          </h3>
          <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '0.2rem' }}>
            Scientific acoustic feature extraction (RMS energy, ZCR, high-frequency energy ratio, pitch shift).
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'rgba(168, 85, 247, 0.1)', border: '1px solid rgba(168, 85, 247, 0.3)', padding: '0.4rem 0.8rem', borderRadius: '8px', fontSize: '0.8rem', color: '#d8b4fe' }}>
          <Lock size={14} /> Ephemeral Processing (Zero Audio Retention)
        </div>
      </div>

      {error && (
        <div style={{ padding: '0.8rem', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.15)', border: '1px solid rgba(239, 68, 68, 0.3)', color: '#f87171', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <AlertTriangle size={16} /> {error}
        </div>
      )}

      {/* Action Buttons */}
      <div style={{ display: 'flex', gap: '0.8rem', flexWrap: 'wrap', marginBottom: '1.5rem' }}>
        <button
          onClick={recordLiveMicrophone}
          disabled={recording || loading}
          style={{
            background: recording ? 'linear-gradient(135deg, #ef4444, #b91c1c)' : 'linear-gradient(135deg, #6366f1, #a855f7)',
            color: '#fff',
            border: 'none',
            borderRadius: '10px',
            padding: '0.6rem 1.2rem',
            fontWeight: 700,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            boxShadow: recording ? '0 0 15px rgba(239, 68, 68, 0.6)' : 'none',
          }}
        >
          <Mic size={16} /> {recording ? 'Recording 2.5s Audio...' : 'Record Voice Sample'}
        </button>

        <span style={{ color: '#64748b', alignSelf: 'center', fontSize: '0.85rem' }}>or Benchmark Presets:</span>

        <button
          onClick={() => runPreset('calm')}
          disabled={loading || recording}
          style={{
            background: 'rgba(16, 185, 129, 0.12)',
            border: '1px solid rgba(16, 185, 129, 0.35)',
            color: '#6ee7b7',
            borderRadius: '10px',
            padding: '0.6rem 1rem',
            cursor: 'pointer',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
          }}
        >
          <Play size={14} /> Normal Speech
        </button>

        <button
          onClick={() => runPreset('anxious')}
          disabled={loading || recording}
          style={{
            background: 'rgba(245, 158, 11, 0.12)',
            border: '1px solid rgba(245, 158, 11, 0.35)',
            color: '#fcd34d',
            borderRadius: '10px',
            padding: '0.6rem 1rem',
            cursor: 'pointer',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
          }}
        >
          <Volume2 size={14} /> Elevated Anxiety
        </button>

        <button
          onClick={() => runPreset('screaming')}
          disabled={loading || recording}
          style={{
            background: 'rgba(239, 68, 68, 0.12)',
            border: '1px solid rgba(239, 68, 68, 0.35)',
            color: '#fca5a5',
            borderRadius: '10px',
            padding: '0.6rem 1rem',
            cursor: 'pointer',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
          }}
        >
          <Sparkles size={14} /> Critical Distress SOS
        </button>
      </div>

      {/* Results Display */}
      {result && (
        <div
          style={{
            background: 'rgba(15, 23, 42, 0.6)',
            borderRadius: '14px',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            padding: '1.4rem',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.2rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <div
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 900,
                  fontSize: '1.3rem',
                  border: `3px solid ${getRiskColor(result.risk_level).border}`,
                  color: getRiskColor(result.risk_level).text,
                  background: getRiskColor(result.risk_level).bg,
                }}
              >
                {(result.distress_score * 100).toFixed(0)}%
              </div>
              <div>
                <span
                  style={{
                    background: getRiskColor(result.risk_level).bg,
                    color: getRiskColor(result.risk_level).text,
                    border: `1px solid ${getRiskColor(result.risk_level).border}`,
                    padding: '0.2rem 0.6rem',
                    borderRadius: '6px',
                    fontSize: '0.8rem',
                    fontWeight: 800,
                    textTransform: 'uppercase',
                  }}
                >
                  {result.risk_level}
                </span>
                <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '0.3rem' }}>
                  Confidence Score: {(result.confidence * 100).toFixed(0)}%
                </p>
              </div>
            </div>

            <div style={{ fontSize: '0.8rem', color: '#64748b', maxWidth: '350px' }}>
              <ShieldCheck size={14} style={{ display: 'inline', color: '#10b981', marginRight: '4px' }} />
              {result.privacy_guarantee}
            </div>
          </div>

          {/* Metric cards */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
              gap: '0.8rem',
            }}
          >
            <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.8rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.05)' }}>
              <span style={{ fontSize: '0.75rem', color: '#64748b' }}>RMS Amplitude</span>
              <p style={{ fontWeight: 700, color: '#f8fafc', fontSize: '1rem', marginTop: '0.2rem' }}>
                {result.features.rms_energy.toFixed(4)}
              </p>
            </div>
            <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.8rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.05)' }}>
              <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Zero-Crossing Rate</span>
              <p style={{ fontWeight: 700, color: '#f8fafc', fontSize: '1rem', marginTop: '0.2rem' }}>
                {result.features.zero_crossing_rate.toFixed(4)}
              </p>
            </div>
            <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.8rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.05)' }}>
              <span style={{ fontSize: '0.75rem', color: '#64748b' }}>High Frequency Ratio</span>
              <p style={{ fontWeight: 700, color: '#f8fafc', fontSize: '1rem', marginTop: '0.2rem' }}>
                {result.features.high_frequency_ratio.toFixed(4)}
              </p>
            </div>
            <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.8rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.05)' }}>
              <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Energy Variance</span>
              <p style={{ fontWeight: 700, color: '#f8fafc', fontSize: '1rem', marginTop: '0.2rem' }}>
                {result.features.amplitude_variance.toFixed(5)}
              </p>
            </div>
            <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.8rem', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.05)' }}>
              <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Estimated Pitch</span>
              <p style={{ fontWeight: 700, color: '#f8fafc', fontSize: '1rem', marginTop: '0.2rem' }}>
                {result.features.estimated_pitch_hz ? `${result.features.estimated_pitch_hz} Hz` : 'N/A'}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
