import React, { useState, useEffect, useRef } from 'react';
import { Mic, MicOff, PhoneCall, AlertTriangle, ShieldAlert, X, Volume2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api/client';

export const GlobalVoiceGuardian: React.FC = () => {
  const { user, token } = useAuth();
  const [isListening, setIsListening] = useState(false);
  const [lastTranscript, setLastTranscript] = useState('');
  const [sosTriggered, setSosTriggered] = useState(false);
  const [triggerKeyword, setTriggerKeyword] = useState('');
  const [guardianPhone, setGuardianPhone] = useState('');
  const [guardianName, setGuardianName] = useState('');
  const [micError, setMicError] = useState<string | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  const [customPhoneInput, setCustomPhoneInput] = useState('');

  const recognitionRef = useRef<any>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);
  const animFrameRef = useRef<number | null>(null);

  // Sync guardian phone from user profile or local storage
  useEffect(() => {
    const savedPhone = user?.emergency_contact_phone || 
      localStorage.getItem('nexa_registered_guardian_phone') || 
      '9916002783'; // default from onboarding
    const savedName = user?.emergency_contact_name || 
      localStorage.getItem('nexa_registered_guardian_name') || 
      'Guardian';
    setGuardianPhone(savedPhone);
    setGuardianName(savedName);
    setCustomPhoneInput(savedPhone);
  }, [user]);

  // Distress Keywords
  const distressKeywords = [
    'nexa help',
    'help',
    'help me',
    'bachao',
    'bachao bachao',
    'emergency',
    'save me',
    'madad'
  ];

  // Initiate Phone Call to Guardian
  const triggerEmergencyCall = (matchedWord: string) => {
    const targetPhone = guardianPhone || '112';
    setTriggerKeyword(matchedWord);
    setSosTriggered(true);

    // Play Alert Audio Frequency
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(880, audioCtx.currentTime); // High pitch siren
      osc.frequency.exponentialRampToValueAtTime(440, audioCtx.currentTime + 0.4);
      gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.5);
    } catch (_) {}

    // Dispatch incident to backend if token present
    if (token) {
      const incId = 'voice_inc_' + Date.now();
      api.recordIncident(token, {
        client_incident_id: incId,
        trigger_type: 'voice_acoustic_safe_word',
        local_created_at: new Date().toISOString(),
      }).then(inc => {
        api.dispatchAlerts(token, inc.id, 'all').catch(() => {});
      }).catch(() => {});
    }

    // Direct phone call initiation (Standard Web / Mobile Protocol)
    // On mobile devices, this prompts the dialer immediately to call the guardian
    setTimeout(() => {
      window.location.href = `tel:${targetPhone}`;
    }, 400);
  };

  // Toggle Continuous Voice Sentinel
  const startListening = async () => {
    setMicError(null);

    // 1. Check Web Speech API support
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

    try {
      // Request mic stream
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaStreamRef.current = stream;

      // Real-time Audio Amplitude & Scream Listener (Fallback)
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      audioContextRef.current = audioCtx;
      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyserRef.current = analyser;
      const source = audioCtx.createMediaStreamSource(stream);
      source.connect(analyser);

      const bufferLength = analyser.frequencyBinCount;
      const dataArray = new Uint8Array(bufferLength);

      const checkAudioLevel = () => {
        if (!analyserRef.current) return;
        analyserRef.current.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < bufferLength; i++) {
          sum += dataArray[i];
        }
        const avg = sum / bufferLength;
        // High-stress acoustic scream detection threshold (> 95 avg level)
        if (avg > 95 && !sosTriggered) {
          triggerEmergencyCall('Acoustic Scream / High Distress Spike');
        }
        animFrameRef.current = requestAnimationFrame(checkAudioLevel);
      };
      animFrameRef.current = requestAnimationFrame(checkAudioLevel);

      // 2. Setup Speech Recognition
      if (SpeechRecognition) {
        const recognition = new SpeechRecognition();
        recognition.continuous = true;
        recognition.interimResults = true;
        recognition.lang = 'en-IN'; // Optimized for Indian English & Hindi keywords like "bachao"

        recognition.onresult = (event: any) => {
          let currentTranscript = '';
          for (let i = event.resultIndex; i < event.results.length; i++) {
            currentTranscript += event.results[i][0].transcript.toLowerCase();
          }

          setLastTranscript(currentTranscript);

          // Check if any distress keyword was spoken
          for (const word of distressKeywords) {
            if (currentTranscript.includes(word)) {
              triggerEmergencyCall(word);
              break;
            }
          }
        };

        recognition.onerror = (event: any) => {
          if (event.error === 'not-allowed') {
            setMicError('Microphone permission blocked. Please allow mic in browser settings.');
            stopListening();
          }
        };

        recognition.onend = () => {
          // Restart recognition continuously if still listening
          if (isListening && recognitionRef.current) {
            try {
              recognition.start();
            } catch (_) {}
          }
        };

        recognitionRef.current = recognition;
        recognition.start();
      }

      setIsListening(true);
    } catch (err: any) {
      setMicError('Microphone permission required to monitor safety phrases.');
      stopListening();
    }
  };

  const stopListening = () => {
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (_) {}
      recognitionRef.current = null;
    }
    if (animFrameRef.current) {
      cancelAnimationFrame(animFrameRef.current);
      animFrameRef.current = null;
    }
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach(t => t.stop());
      mediaStreamRef.current = null;
    }
    if (audioContextRef.current) {
      audioContextRef.current.close().catch(() => {});
      audioContextRef.current = null;
    }
    setIsListening(false);
    setLastTranscript('');
  };

  const toggleVoiceSentinel = () => {
    if (isListening) {
      stopListening();
    } else {
      startListening();
    }
  };

  const handleSaveCustomPhone = () => {
    const cleaned = customPhoneInput.trim();
    if (cleaned) {
      setGuardianPhone(cleaned);
      localStorage.setItem('nexa_registered_guardian_phone', cleaned);
      setShowConfig(false);
    }
  };

  return (
    <>
      {/* 1. EMERGENCY TRIGGER MODAL OVERLAY */}
      {sosTriggered && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.92)',
            backdropFilter: 'blur(10px)',
            zIndex: 99999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '1rem'
          }}
          className="animate-fade-in"
        >
          <div 
            style={{
              background: '#0f172a',
              border: '2px solid #ef4444',
              borderRadius: '24px',
              padding: 'clamp(1.5rem, 5vw, 2.5rem)',
              maxWidth: '480px',
              width: '100%',
              textAlign: 'center',
              boxShadow: '0 0 50px rgba(239, 68, 68, 0.5)',
              color: '#ffffff'
            }}
          >
            <div 
              style={{
                width: '72px',
                height: '72px',
                borderRadius: '50%',
                background: 'rgba(239, 68, 68, 0.2)',
                border: '2px solid #ef4444',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 1.25rem',
                animation: 'radarPing 1.5s infinite'
              }}
            >
              <ShieldAlert size={40} color="#ef4444" />
            </div>

            <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#f87171', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              DISTRESS SAFE-PHRASE TRIGGERED
            </span>
            <h2 style={{ fontSize: '1.6rem', fontWeight: 800, margin: '0.5rem 0' }}>
              Calling Guardian Now
            </h2>
            <p style={{ fontSize: '0.9rem', color: '#cbd5e1', marginBottom: '1.5rem', lineHeight: 1.5 }}>
              Distress keyword <strong style={{ color: '#fca5a5' }}>"{triggerKeyword}"</strong> recognized. Automatically establishing cellular voice call to your emergency contact.
            </p>

            <div style={{ background: '#1e293b', padding: '1rem', borderRadius: '16px', marginBottom: '1.5rem', border: '1px solid #334155' }}>
              <span style={{ fontSize: '0.75rem', color: '#94a3b8', textTransform: 'uppercase', display: 'block', fontWeight: 700 }}>
                Target Emergency Line
              </span>
              <strong style={{ fontSize: '1.35rem', color: '#38bdf8', letterSpacing: '0.05em' }}>
                {guardianName} ({guardianPhone})
              </strong>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              <a
                href={`tel:${guardianPhone}`}
                style={{
                  background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                  color: '#ffffff',
                  padding: '1rem',
                  borderRadius: '14px',
                  fontWeight: 800,
                  fontSize: '1.05rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.6rem',
                  textDecoration: 'none',
                  boxShadow: '0 8px 24px rgba(239, 68, 68, 0.4)'
                }}
              >
                <PhoneCall size={20} />
                <span>Immediate Call: {guardianPhone}</span>
              </a>

              <a
                href="tel:112"
                style={{
                  background: '#1e293b',
                  color: '#ffffff',
                  padding: '0.85rem',
                  borderRadius: '14px',
                  fontWeight: 700,
                  fontSize: '0.95rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  textDecoration: 'none',
                  border: '1px solid #475569'
                }}
              >
                <PhoneCall size={18} color="#fca5a5" />
                <span>Dial 112 (National Police Control)</span>
              </a>

              <button
                type="button"
                onClick={() => setSosTriggered(false)}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: '#94a3b8',
                  padding: '0.5rem',
                  fontSize: '0.85rem',
                  cursor: 'pointer',
                  fontWeight: 600
                }}
              >
                Dismiss / I am Safe
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 2. FLOATING VOICE GUARDIAN SENTINEL BAR */}
      <div 
        className="floating-voice-sentinel"
        style={{
          position: 'fixed',
          bottom: '20px',
          right: '20px',
          zIndex: 9999,
          maxWidth: 'min(94vw, 420px)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-end',
          gap: '0.5rem',
          fontFamily: 'inherit'
        }}
      >
        {/* Error pill if mic blocked */}
        {micError && (
          <div 
            style={{
              background: '#ef4444',
              color: '#ffffff',
              padding: '0.5rem 0.85rem',
              borderRadius: '12px',
              fontSize: '0.78rem',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              boxShadow: '0 4px 14px rgba(239, 68, 68, 0.3)'
            }}
          >
            <AlertTriangle size={14} />
            <span>{micError}</span>
            <button onClick={() => setMicError(null)} style={{ background: 'none', border: 'none', color: '#fff', cursor: 'pointer', padding: 0 }}>
              <X size={13} />
            </button>
          </div>
        )}

        {/* Custom Phone Configuration Popover */}
        {showConfig && (
          <div 
            style={{
              background: '#0f172a',
              border: '1px solid #334155',
              padding: '1rem',
              borderRadius: '16px',
              boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
              color: '#ffffff',
              width: '280px',
              textAlign: 'left'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.82rem', fontWeight: 700 }}>Guardian Emergency Number</span>
              <button onClick={() => setShowConfig(false)} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}>
                <X size={14} />
              </button>
            </div>
            <input 
              type="tel"
              value={customPhoneInput}
              onChange={(e) => setCustomPhoneInput(e.target.value)}
              placeholder="e.g. 9916002783"
              style={{
                width: '100%',
                padding: '0.5rem 0.75rem',
                borderRadius: '8px',
                border: '1px solid #475569',
                background: '#1e293b',
                color: '#fff',
                fontSize: '14px',
                marginBottom: '0.65rem',
                boxSizing: 'border-box'
              }}
            />
            <button 
              onClick={handleSaveCustomPhone}
              style={{
                width: '100%',
                background: '#6366f1',
                color: '#fff',
                border: 'none',
                borderRadius: '8px',
                padding: '0.5rem',
                fontSize: '0.82rem',
                fontWeight: 700,
                cursor: 'pointer'
              }}
            >
              Save Guardian Line
            </button>
          </div>
        )}

        {/* Main Floating Sentinel Pill */}
        <div 
          style={{
            background: isListening 
              ? 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)' 
              : 'rgba(15, 23, 42, 0.95)',
            border: isListening ? '1.5px solid #818cf8' : '1px solid #334155',
            borderRadius: '9999px',
            padding: '0.45rem 0.65rem 0.45rem 0.85rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            boxShadow: isListening 
              ? '0 8px 30px rgba(99, 102, 241, 0.45)' 
              : '0 6px 20px rgba(0,0,0,0.3)',
            color: '#ffffff',
            backdropFilter: 'blur(12px)'
          }}
        >
          {/* Status Indicator & Live Text */}
          <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <span 
                style={{
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  background: isListening ? '#10b981' : '#94a3b8',
                  boxShadow: isListening ? '0 0 10px #10b981' : 'none'
                }}
              ></span>
              <span style={{ fontSize: '0.78rem', fontWeight: 800, letterSpacing: '0.02em' }}>
                {isListening ? 'VOICE SENTINEL ON' : 'VOICE SENTINEL OFF'}
              </span>
            </div>
            <span style={{ fontSize: '0.68rem', color: isListening ? '#a5b4fc' : '#94a3b8' }}>
              {isListening 
                ? (lastTranscript ? `Heard: "${lastTranscript.slice(-18)}"` : 'Say "Nexa Help", "Bachao", or "Help"')
                : 'Turn on for voice emergency call'}
            </span>
          </div>

          {/* Action Buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            {/* Mic Toggle Button */}
            <button
              id="btn-voice-sentinel-toggle"
              type="button"
              onClick={toggleVoiceSentinel}
              title={isListening ? 'Click to Mute Voice Sentinel' : 'Click to Turn On Voice Emergency Call'}
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '50%',
                border: 'none',
                background: isListening 
                  ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)' 
                  : 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)',
                color: '#ffffff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                boxShadow: isListening 
                  ? '0 0 15px rgba(16, 185, 129, 0.5)' 
                  : '0 4px 12px rgba(99, 102, 241, 0.35)',
                transition: 'transform 0.2s ease'
              }}
            >
              {isListening ? <Mic size={18} /> : <MicOff size={18} />}
            </button>

            {/* Direct Instant Call Guardian Shortcut Button */}
            <a
              href={`tel:${guardianPhone || '112'}`}
              id="btn-voice-sentinel-quickcall"
              title={`Direct Call Guardian: ${guardianPhone}`}
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '50%',
                background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                color: '#ffffff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                textDecoration: 'none',
                boxShadow: '0 4px 12px rgba(239, 68, 68, 0.35)'
              }}
            >
              <PhoneCall size={18} />
            </a>

            {/* Config Button */}
            <button
              onClick={() => setShowConfig(!showConfig)}
              title="Configure Guardian Phone"
              style={{
                background: 'transparent',
                border: 'none',
                color: '#94a3b8',
                cursor: 'pointer',
                padding: '4px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <Volume2 size={16} />
            </button>
          </div>
        </div>
      </div>
    </>
  );
};
