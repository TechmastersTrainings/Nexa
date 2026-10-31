import React, { useState, useRef, useEffect } from 'react';
import { api } from '../api/client';
import type { StressAnalysisResult } from '../api/client';
import {
  Activity,
  Mic,
  MicOff,
  Volume2,
  AlertTriangle,
  Lock,
  Play
} from 'lucide-react';

interface VoiceStressBenchProps {
  token: string;
}

export const VoiceStressBench: React.FC<VoiceStressBenchProps> = ({ token }) => {
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState<StressAnalysisResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isRecordingLive, setIsRecordingLive] = useState(false);
  const [liveVolume, setLiveVolume] = useState<number>(0);

  // Audio Context & Canvas Refs for Real-Time Waveform
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);

  // Cleanup Web Audio on unmount
  useEffect(() => {
    return () => {
      stopLiveMic();
    };
  }, []);

  // Real-Time Audio Canvas Visualizer
  const startLiveMic = async () => {
    try {
      setError(null);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaStreamRef.current = stream;

      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      audioContextRef.current = audioCtx;

      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyserRef.current = analyser;

      const source = audioCtx.createMediaStreamSource(stream);
      source.connect(analyser);

      setIsRecordingLive(true);
      drawWaveform();
    } catch (err: any) {
      setError('Microphone access denied or unavailable. You can use sample audio simulations below.');
    }
  };

  const stopLiveMic = () => {
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current);
    }
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach((track) => track.stop());
      mediaStreamRef.current = null;
    }
    if (audioContextRef.current) {
      audioContextRef.current.close().catch(() => {});
      audioContextRef.current = null;
    }
    setIsRecordingLive(false);
    setLiveVolume(0);
  };

  const drawWaveform = () => {
    if (!canvasRef.current || !analyserRef.current) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const analyser = analyserRef.current;
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const render = () => {
      animationFrameRef.current = requestAnimationFrame(render);
      analyser.getByteFrequencyData(dataArray);

      let sum = 0;
      for (let i = 0; i < bufferLength; i++) {
        sum += dataArray[i];
      }
      const avg = sum / bufferLength;
      setLiveVolume(Math.round((avg / 255) * 100));

      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const barWidth = (canvas.width / bufferLength) * 2.2;
      let x = 0;

      for (let i = 0; i < bufferLength; i++) {
        const barHeight = (dataArray[i] / 255) * canvas.height;
        // Radiant Violet to Rose Gradient Bars
        const hue = 260 + (dataArray[i] / 255) * 70; // 260 (purple) to 330 (rose)
        ctx.fillStyle = `hsl(${hue}, 85%, 60%)`;
        ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
        x += barWidth + 1.5;
      }
    };

    render();
  };

  // Run Backend Acoustic Feature Extraction
  const analyzeSample = async (distressLevel: 'screaming' | 'calm' | 'loud') => {
    try {
      setAnalyzing(true);
      setError(null);

      // Generate synthetic WAV PCM buffer matching condition
      const sampleRate = 16000;
      const duration = 0.5;
      const numSamples = Math.floor(sampleRate * duration);
      const buffer = new ArrayBuffer(44 + numSamples * 2);
      const view = new DataView(buffer);

      // RIFF header
      writeString(view, 0, 'RIFF');
      view.setUint32(4, 36 + numSamples * 2, true);
      writeString(view, 8, 'WAVE');
      writeString(view, 12, 'fmt ');
      view.setUint32(16, 16, true);
      view.setUint16(20, 1, true); // PCM
      view.setUint16(22, 1, true); // Mono
      view.setUint32(24, sampleRate, true);
      view.setUint32(28, sampleRate * 2, true);
      view.setUint16(32, 2, true);
      view.setUint16(34, 16, true);
      writeString(view, 36, 'data');
      view.setUint32(40, numSamples * 2, true);

      // Synthesize tone based on condition
      const freq = distressLevel === 'screaming' ? 950 : distressLevel === 'loud' ? 650 : 250;
      const amp = distressLevel === 'screaming' ? 0.9 : distressLevel === 'loud' ? 0.7 : 0.2;

      for (let i = 0; i < numSamples; i++) {
        const t = i / sampleRate;
        const val = amp * Math.sin(2 * Math.PI * freq * t);
        view.setInt16(44 + i * 2, val * 32767, true);
      }

      const blob = new Blob([buffer], { type: 'audio/wav' });
      const file = new File([blob], `${distressLevel}_test.wav`, { type: 'audio/wav' });

      const data = await api.analyzeStressFile(token, file);
      setResult(data);
    } catch (err: any) {
      setError(err.message || 'Acoustic ML classification failed');
    } finally {
      setAnalyzing(false);
    }
  };

  const writeString = (view: DataView, offset: number, string: string) => {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  };

  const isDistress = result ? result.risk_level !== 'NORMAL' : false;

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Header Banner */}
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
              ML DISTRESS ANALYSIS
            </span>
          </div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <Activity style={{ color: '#7c3aed' }} /> Acoustic Voice-Stress AI Engine
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginTop: '0.2rem' }}>
            Acoustic feature extraction (RMS Energy, Zero-Crossing Rate, High-Frequency ratio, Pitch jitter) with zero audio storage.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#f8fafc', border: '1px solid var(--border-subtle)', padding: '0.45rem 0.9rem', borderRadius: 'var(--radius-md)', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
          <Lock size={14} style={{ color: '#059669' }} /> Ephemeral Memory (Zero Cloud Audio Retention)
        </div>
      </div>

      {error && (
        <div style={{ padding: '0.85rem 1.25rem', borderRadius: 'var(--radius-md)', background: '#fff1f2', border: '1px solid #fecdd3', color: '#9f1239', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600 }}>
          <AlertTriangle size={18} /> {error}
        </div>
      )}

      {/* Real-Time Live Microphone Visualizer Card */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border-subtle)',
          padding: '1.5rem',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Mic size={18} style={{ color: isRecordingLive ? '#f43f5e' : '#7c3aed' }} />
              {isRecordingLive ? 'Live Microphone Stream Active' : 'Real-Time Microphone Acoustic Visualizer'}
            </h3>
            <p style={{ fontSize: '0.84rem', color: 'var(--text-secondary)' }}>
              Stream your device microphone to analyze vocal frequencies and acoustic stress oscillations in real time.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.6rem' }}>
            {!isRecordingLive ? (
              <button
                id="btn-start-live-mic"
                onClick={startLiveMic}
                style={{
                  background: 'linear-gradient(135deg, #7c3aed 0%, #ec4899 100%)',
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.6rem 1.25rem',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer',
                  boxShadow: '0 6px 18px rgba(124, 58, 237, 0.3)',
                }}
              >
                <Mic size={16} /> Start Live Mic
              </button>
            ) : (
              <button
                id="btn-stop-live-mic"
                onClick={stopLiveMic}
                style={{
                  background: '#f43f5e',
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: 'var(--radius-md)',
                  padding: '0.6rem 1.25rem',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer',
                }}
              >
                <MicOff size={16} /> Stop Mic
              </button>
            )}
          </div>
        </div>

        {/* Audio Spectrum Canvas */}
        <div style={{ background: '#0f172a', borderRadius: 'var(--radius-md)', padding: '1rem', position: 'relative', overflow: 'hidden' }}>
          <canvas
            ref={canvasRef}
            width={640}
            height={120}
            style={{ width: '100%', height: '120px', display: 'block' }}
          />

          {!isRecordingLive && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(15, 23, 42, 0.75)', color: '#94a3b8', fontSize: '0.9rem', gap: '0.5rem' }}>
              <Volume2 size={18} /> Click "Start Live Mic" or run an acoustic test simulation below
            </div>
          )}
        </div>

        {isRecordingLive && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginTop: '1rem' }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Live Amplitude:</span>
            <div style={{ flex: 1, height: '8px', background: '#e2e8f0', borderRadius: '999px', overflow: 'hidden' }}>
              <div style={{ width: `${liveVolume}%`, height: '100%', background: liveVolume > 70 ? '#f43f5e' : '#7c3aed', transition: 'width 0.1s ease' }} />
            </div>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: liveVolume > 70 ? '#f43f5e' : '#7c3aed' }}>
              {liveVolume}%
            </span>
          </div>
        )}
      </div>

      {/* Interactive Acoustic Simulation Bench */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border-subtle)',
          padding: '1.5rem',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.4rem' }}>
          Acoustic ML Benchmark Simulations
        </h3>
        <p style={{ fontSize: '0.86rem', color: 'var(--text-secondary)', marginBottom: '1.25rem' }}>
          Test the neural audio classifier with calibrated stress benchmarks to evaluate distress score accuracy:
        </p>

        <div style={{ display: 'flex', gap: '0.85rem', flexWrap: 'wrap', marginBottom: '1.5rem' }}>
          <button
            id="btn-sample-distress"
            onClick={() => analyzeSample('screaming')}
            disabled={analyzing}
            style={{
              background: '#fff1f2',
              border: '1.5px solid #fecdd3',
              color: '#e11d48',
              borderRadius: 'var(--radius-md)',
              padding: '0.65rem 1.25rem',
              fontWeight: 700,
              fontSize: '0.88rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
            }}
          >
            <Play size={15} /> Screaming / Distress Audio
          </button>

          <button
            id="btn-sample-loud"
            onClick={() => analyzeSample('loud')}
            disabled={analyzing}
            style={{
              background: '#fffbeb',
              border: '1.5px solid #fde68a',
              color: '#d97706',
              borderRadius: 'var(--radius-md)',
              padding: '0.65rem 1.25rem',
              fontWeight: 700,
              fontSize: '0.88rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
            }}
          >
            <Play size={15} /> Agitated Voice Audio
          </button>

          <button
            id="btn-sample-calm"
            onClick={() => analyzeSample('calm')}
            disabled={analyzing}
            style={{
              background: '#ecfdf5',
              border: '1.5px solid #a7f3d0',
              color: '#059669',
              borderRadius: 'var(--radius-md)',
              padding: '0.65rem 1.25rem',
              fontWeight: 700,
              fontSize: '0.88rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
            }}
          >
            <Play size={15} /> Calm Voice Benchmark
          </button>
        </div>

        {/* Results Visualizer Card */}
        {result && (
          <div
            style={{
              background: '#f8fafc',
              border: '1px solid var(--border-subtle)',
              borderRadius: 'var(--radius-md)',
              padding: '1.5rem',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
              <div>
                <span style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                  Acoustic Classification Verdict
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginTop: '0.2rem' }}>
                  <h4 style={{ fontSize: '1.35rem', fontWeight: 800, color: isDistress ? '#e11d48' : '#059669' }}>
                    {isDistress ? `🚨 ${result.risk_level.replace('_', ' ')}` : '✅ NORMAL SPEECH (CALM)'}
                  </h4>
                  <span style={{ fontSize: '0.78rem', fontWeight: 700, padding: '0.2rem 0.6rem', borderRadius: 'var(--radius-full)', background: isDistress ? '#fee2e2' : '#dcfce7', color: isDistress ? '#b91c1c' : '#15803d' }}>
                    Confidence: {(result.confidence * 100).toFixed(1)}%
                  </span>
                </div>
              </div>

              <div style={{ textAlign: 'right' }}>
                <span style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)' }}>Distress Index</span>
                <div style={{ fontSize: '1.8rem', fontWeight: 900, color: isDistress ? '#e11d48' : '#059669' }}>
                  {(result.distress_score * 100).toFixed(0)}%
                </div>
              </div>
            </div>

            {/* Extracted Acoustic Features Matrix */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
              <div style={{ background: '#ffffff', padding: '0.85rem 1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>RMS Amplitude</span>
                <strong style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{result.features.rms_energy.toFixed(4)}</strong>
              </div>

              <div style={{ background: '#ffffff', padding: '0.85rem 1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>Zero-Crossing Rate</span>
                <strong style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{result.features.zero_crossing_rate.toFixed(4)}</strong>
              </div>

              <div style={{ background: '#ffffff', padding: '0.85rem 1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>High-Frequency Energy</span>
                <strong style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{(result.features.high_frequency_ratio * 100).toFixed(1)}%</strong>
              </div>

              <div style={{ background: '#ffffff', padding: '0.85rem 1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>Pitch Frequency</span>
                <strong style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>
                  {result.features.estimated_pitch_hz !== null ? `${result.features.estimated_pitch_hz.toFixed(1)} Hz` : 'Unvoiced'}
                </strong>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
