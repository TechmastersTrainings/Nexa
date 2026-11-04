import React, { useState } from 'react';
import { 
  Mic, 
  Lock, 
  ArrowRight, 
  Shield, 
  PhoneCall, 
  ShieldAlert, 
  Activity, 
  CheckCircle2, 
  Sparkles,
  HeartPulse,
  Copy,
  Play,
  Check,
  ShieldCheck,
  Radio
} from 'lucide-react';

interface LandingHeroProps {
  onOpenAuth: (mode: 'login' | 'register') => void;
}

export const LandingHero: React.FC<LandingHeroProps> = ({ onOpenAuth }) => {
  // Interactive Simulator State
  const [simTrigger, setSimTrigger] = useState<'voice' | 'scream' | 'panic'>('voice');
  const [simRunning, setSimRunning] = useState(false);
  const [simStep, setSimStep] = useState<number>(0);
  const [copiedHelpline, setCopiedHelpline] = useState<string | null>(null);

  const handleRunSimulator = () => {
    setSimRunning(true);
    setSimStep(1);

    setTimeout(() => {
      setSimStep(2);
    }, 900);

    setTimeout(() => {
      setSimStep(3);
    }, 1800);

    setTimeout(() => {
      setSimStep(4);
      setSimRunning(false);
    }, 2800);
  };

  const handleCopyNumber = (num: string) => {
    navigator.clipboard.writeText(num);
    setCopiedHelpline(num);
    setTimeout(() => setCopiedHelpline(null), 2500);
  };

  return (
    <div className="landing-container animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem', width: '100%', maxWidth: '100%', boxSizing: 'border-box' }}>
      
      {/* 1. TOP EMERGENCY LIFELINE QUICK DIALER BAR */}
      <div 
        className="emergency-lifeline-bar"
        style={{
          background: 'linear-gradient(90deg, #0f172a 0%, #1e1b4b 100%)',
          borderRadius: 'var(--radius-lg)',
          padding: '0.85rem 1.25rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '0.85rem',
          border: '1px solid rgba(255,255,255,0.12)',
          boxShadow: 'var(--shadow-md)',
          width: '100%',
          boxSizing: 'border-box'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
          <span className="status-dot online" style={{ background: '#f43f5e', boxShadow: '0 0 10px #f43f5e' }}></span>
          <span style={{ fontSize: '0.82rem', fontWeight: 800, color: '#ffffff', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            National 24/7 Emergency Helplines (Instant Access)
          </span>
        </div>

        <div className="helpline-quick-btns" style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem', width: 'auto' }}>
          <a
            href="tel:112"
            title="Dial 112 National Police Emergency"
            style={{
              background: 'rgba(239, 68, 68, 0.22)',
              border: '1px solid #ef4444',
              color: '#fca5a5',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.8rem',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              textDecoration: 'none'
            }}
          >
            <PhoneCall size={13} />
            <span>Call 112 (Police)</span>
          </a>

          <a
            href="tel:1091"
            title="Dial 1091 Women Safety Helpline"
            style={{
              background: 'rgba(236, 72, 153, 0.22)',
              border: '1px solid #ec4899',
              color: '#fbcfe8',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.8rem',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              textDecoration: 'none'
            }}
          >
            <PhoneCall size={13} />
            <span>1091 Women Helpline</span>
          </a>

          <a
            href="tel:181"
            title="Dial 181 Women in Distress Helpline"
            style={{
              background: 'rgba(168, 85, 247, 0.22)',
              border: '1px solid #a855f7',
              color: '#e9d5ff',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.8rem',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              textDecoration: 'none'
            }}
          >
            <PhoneCall size={13} />
            <span>181 Crisis Helpline</span>
          </a>

          <a
            href="tel:108"
            title="Dial 108 Emergency Medical Ambulance"
            style={{
              background: 'rgba(14, 165, 233, 0.22)',
              border: '1px solid #0ea5e9',
              color: '#bae6fd',
              padding: '0.45rem 0.95rem',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.8rem',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              textDecoration: 'none'
            }}
          >
            <HeartPulse size={13} />
            <span>108 Ambulance</span>
          </a>
        </div>
      </div>

      {/* 2. MAIN HERO SECTION */}
      <section className="hero-section" style={{ padding: '2rem 1rem 3rem' }}>
        <div className="hero-pill" style={{ margin: '0 auto 1.5rem auto' }}>
          <Sparkles size={14} className="text-indigo" />
          <span>RESEARCH-BACKED WOMEN SAFETY SENTINEL • 24/7 PROTECTION</span>
        </div>

        <h1 className="hero-heading" style={{ marginBottom: '1.25rem' }}>
          Fearless Independence. <br />
          <span className="text-gradient">Protected by Intelligent AI.</span>
        </h1>

        <p className="hero-description" style={{ margin: '0 auto 2.25rem auto' }}>
          Nexa AI empowers every woman with an active, unbroken security shield. Built with 
          <strong> native offline acoustic distress recognition</strong>, automated <strong>112 police emergency coordination</strong>, 
          instant <strong>guardian SMS dispatch</strong> with live GPS coordinates, and verified safe sanctuaries when seconds count.
        </p>

        <div className="hero-actions" style={{ marginBottom: '2.5rem' }}>
          <button 
            id="btn-hero-register"
            className="btn-hero-primary" 
            onClick={() => onOpenAuth('register')}
            style={{ padding: '0.95rem 2rem', fontSize: '1rem', fontWeight: 800 }}
          >
            <Shield size={20} />
            <span>Activate 100% Protected Shield</span>
            <ArrowRight size={18} />
          </button>

          <button 
            id="btn-hero-login"
            className="btn-hero-secondary" 
            onClick={() => onOpenAuth('login')}
            style={{ padding: '0.95rem 1.8rem', fontSize: '1rem' }}
          >
            <Lock size={18} />
            <span>Sign In to Guardian Portal</span>
          </button>
        </div>

        {/* Real-World Safety Metrics Bar */}
        <div 
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '1rem',
            maxWidth: '920px',
            margin: '0 auto',
            textAlign: 'left'
          }}
        >
          <div style={{ background: '#ffffff', padding: '1.25rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0', boxShadow: 'var(--shadow-sm)' }}>
            <span style={{ fontSize: '1.75rem', fontWeight: 800, color: '#7c3aed', display: 'block' }}>&lt; 3.0s</span>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginTop: '0.2rem' }}>
              Average Dispatch Speed
            </span>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
              From trigger detection to emergency SMS & police broadcast transmission.
            </span>
          </div>

          <div style={{ background: '#ffffff', padding: '1.25rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0', boxShadow: 'var(--shadow-sm)' }}>
            <span style={{ fontSize: '1.75rem', fontWeight: 800, color: '#059669', display: 'block' }}>100% Offline</span>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginTop: '0.2rem' }}>
              On-Device Acoustic AI
            </span>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
              Understands distress keywords even without active mobile data or Wi-Fi.
            </span>
          </div>

          <div style={{ background: '#ffffff', padding: '1.25rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0', boxShadow: 'var(--shadow-sm)' }}>
            <span style={{ fontSize: '1.75rem', fontWeight: 800, color: '#e11d48', display: 'block' }}>112 & 1091</span>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginTop: '0.2rem' }}>
              Direct Police Hotline Dialing
            </span>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
              Immediate one-tap connection to national police & specialized women desks.
            </span>
          </div>

          <div style={{ background: '#ffffff', padding: '1.25rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0', boxShadow: 'var(--shadow-sm)' }}>
            <span style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0284c7', display: 'block' }}>Zero Tracking</span>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginTop: '0.2rem' }}>
              Guaranteed Data Sovereignty
            </span>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
              Location tracking is strictly dormant and activates only upon emergency SOS.
            </span>
          </div>
        </div>
      </section>

      {/* 3. INTERACTIVE SOS RESPONSE SIMULATOR */}
      <section 
        className="simulator-section"
        style={{
          background: 'linear-gradient(135deg, #ffffff 0%, #f8faff 100%)',
          borderRadius: 'var(--radius-xl)',
          padding: 'clamp(1.25rem, 4vw, 2.5rem) clamp(0.75rem, 3vw, 1.5rem)',
          border: '1px solid #cbd5e1',
          boxShadow: 'var(--shadow-lg)',
          width: '100%',
          boxSizing: 'border-box'
        }}
      >
        <div style={{ textAlign: 'center', maxWidth: '680px', margin: '0 auto 2rem auto' }}>
          <div className="status-badge-live" style={{ marginBottom: '0.5rem' }}>
            <Radio size={14} className="text-rose" />
            <span>LIVE INTERACTIVE SIMULATION</span>
          </div>
          <h2 style={{ fontSize: 'clamp(1.4rem, 4.5vw, 1.9rem)', fontWeight: 800, color: 'var(--text-primary)' }}>
            Experience The 3-Second Rescue Protocol
          </h2>
          <p style={{ fontSize: '0.92rem', color: 'var(--text-secondary)', marginTop: '0.4rem' }}>
            Select a real-world emergency distress scenario below and test how Nexa AI coordinates parallel defense measures instantly.
          </p>
        </div>

        {/* Trigger Selector Buttons */}
        <div className="sim-trigger-btn-group" style={{ display: 'flex', justifyContent: 'center', flexWrap: 'wrap', gap: '0.65rem', marginBottom: '2rem' }}>
          <button
            type="button"
            onClick={() => { setSimTrigger('voice'); setSimStep(0); }}
            style={{
              padding: '0.65rem 1rem',
              borderRadius: 'var(--radius-md)',
              border: simTrigger === 'voice' ? '2px solid #7c3aed' : '1px solid #cbd5e1',
              background: simTrigger === 'voice' ? '#ede9fe' : '#ffffff',
              color: simTrigger === 'voice' ? '#6d28d9' : 'var(--text-secondary)',
              fontWeight: 700,
              fontSize: '0.85rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <Mic size={16} />
            <span>Scenario A: Voice Whisper ("Help me Nexa")</span>
          </button>

          <button
            type="button"
            onClick={() => { setSimTrigger('scream'); setSimStep(0); }}
            style={{
              padding: '0.65rem 1rem',
              borderRadius: 'var(--radius-md)',
              border: simTrigger === 'scream' ? '2px solid #e11d48' : '1px solid #cbd5e1',
              background: simTrigger === 'scream' ? '#ffe4e6' : '#ffffff',
              color: simTrigger === 'scream' ? '#be123c' : 'var(--text-secondary)',
              fontWeight: 700,
              fontSize: '0.85rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <Activity size={16} />
            <span>Scenario B: Acoustic Scream & Fear Spike</span>
          </button>

          <button
            type="button"
            onClick={() => { setSimTrigger('panic'); setSimStep(0); }}
            style={{
              padding: '0.65rem 1rem',
              borderRadius: 'var(--radius-md)',
              border: simTrigger === 'panic' ? '2px solid #0284c7' : '1px solid #cbd5e1',
              background: simTrigger === 'panic' ? '#e0f2fe' : '#ffffff',
              color: simTrigger === 'panic' ? '#0369a1' : 'var(--text-secondary)',
              fontWeight: 700,
              fontSize: '0.85rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <ShieldAlert size={16} />
            <span>Scenario C: One-Touch Covert Panic Button</span>
          </button>
        </div>

        {/* Simulator Console Card */}
        <div 
          style={{
            maxWidth: '820px',
            width: '100%',
            boxSizing: 'border-box',
            margin: '0 auto',
            background: '#0f172a',
            color: '#f8fafc',
            borderRadius: 'var(--radius-lg)',
            padding: 'clamp(1rem, 3vw, 1.75rem)',
            border: '1px solid #334155',
            boxShadow: 'var(--shadow-lg)'
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', borderBottom: '1px solid #1e293b', paddingBottom: '0.75rem', flexWrap: 'wrap', gap: '0.75rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: simRunning ? '#f43f5e' : '#10b981', flexShrink: 0 }}></div>
              <span style={{ fontSize: 'clamp(0.72rem, 2.5vw, 0.85rem)', fontWeight: 700, letterSpacing: '0.04em' }}>
                NEXA EMERGENCY TELEMETRY TERMINAL (SIMULATOR)
              </span>
            </div>

            <button
              onClick={handleRunSimulator}
              disabled={simRunning}
              style={{
                background: simRunning ? '#334155' : 'linear-gradient(135deg, #f43f5e 0%, #e11d48 100%)',
                color: '#ffffff',
                border: 'none',
                borderRadius: 'var(--radius-md)',
                padding: '0.55rem 1.15rem',
                fontSize: '0.82rem',
                fontWeight: 800,
                cursor: simRunning ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem'
              }}
            >
              <Play size={14} />
              <span>{simRunning ? 'Executing Rescue Chain...' : 'Trigger Simulation Test'}</span>
            </button>
          </div>

          {/* Stepper Timeline */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {/* Step 1 */}
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.85rem', opacity: simStep >= 1 ? 1 : 0.35, transition: 'opacity 0.4s ease' }}>
              <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: simStep >= 1 ? '#7c3aed' : '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontWeight: 700, fontSize: '0.82rem' }}>
                1
              </div>
              <div>
                <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#e2e8f0', display: 'block' }}>
                  {simTrigger === 'voice' && 'Acoustic Safe-Phrase Detected ("Help me Nexa")'}
                  {simTrigger === 'scream' && 'Distress Spectral Frequency Confirmed (>880Hz Scream Pattern)'}
                  {simTrigger === 'panic' && 'Hardware Covert SOS Pulse Initiated'}
                </span>
                <span style={{ fontSize: '0.8rem', color: '#94a3b8' }}>
                  Distress classified on-device in 0.18s. Device vibrating silently to confirm distress acknowledgment.
                </span>
              </div>
            </div>

            {/* Step 2 */}
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.85rem', opacity: simStep >= 2 ? 1 : 0.35, transition: 'opacity 0.4s ease' }}>
              <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: simStep >= 2 ? '#0284c7' : '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontWeight: 700, fontSize: '0.82rem' }}>
                2
              </div>
              <div>
                <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#e2e8f0', display: 'block' }}>
                  GPS Telemetry Locked & Dossier Assembled
                </span>
                <span style={{ fontSize: '0.8rem', color: '#94a3b8' }}>
                  High-accuracy coordinates (12.9716°N, 77.5946°E ±4m) combined with Blood Group (O+), Safe Base, and Emergency Contacts.
                </span>
              </div>
            </div>

            {/* Step 3 */}
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.85rem', opacity: simStep >= 3 ? 1 : 0.35, transition: 'opacity 0.4s ease' }}>
              <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: simStep >= 3 ? '#e11d48' : '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontWeight: 700, fontSize: '0.82rem' }}>
                3
              </div>
              <div>
                <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#fca5a5', display: 'block' }}>
                  Parallel Broadcast Transmitted (Guardian SMS + 112 PCR Routing)
                </span>
                <span style={{ fontSize: '0.8rem', color: '#cbd5e1' }}>
                  <em>"EMERGENCY SOS: Priya Sharma triggered distress! Live Location: https://maps.google.com/?q=12.9716,77.5946 | Battery: 88% | Blood: O+. Check immediately!"</em>
                </span>
              </div>
            </div>

            {/* Step 4 */}
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.85rem', opacity: simStep >= 4 ? 1 : 0.35, transition: 'opacity 0.4s ease' }}>
              <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: simStep >= 4 ? '#059669' : '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontWeight: 700, fontSize: '0.82rem' }}>
                4
              </div>
              <div>
                <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#6ee7b7', display: 'block' }}>
                  Sanctuary Safe Haven Navigation Active
                </span>
                <span style={{ fontSize: '0.8rem', color: '#94a3b8' }}>
                  Nearest verified 24/7 Police Station & Hospital Desk identified 380m North-East. Responders tracking live movement until safe arrival.
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 4. COMPREHENSIVE NATIONAL SAFETY & POLICE DIRECTORY */}
      <section>
        <div style={{ textAlign: 'center', maxWidth: '640px', margin: '0 auto 2rem auto' }}>
          <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#059669', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Verified Emergency Contacts
          </span>
          <h2 style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--text-primary)', marginTop: '0.3rem' }}>
            Official Emergency Helpline Directory
          </h2>
          <p style={{ fontSize: '0.92rem', color: 'var(--text-secondary)', marginTop: '0.4rem' }}>
            Save or directly dial these national helplines. Each is fully recognized and integrated with central control dispatchers.
          </p>
        </div>

        <div className="helpline-directory-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 260px), 1fr))', gap: '1.25rem', width: '100%', boxSizing: 'border-box' }}>
          {[
            {
              num: '112',
              title: 'National Unified Emergency',
              desc: 'Single pan-India emergency number for Police, Fire, and Medical rescue dispatch.',
              badge: '24/7 Government PCR',
              color: '#ef4444'
            },
            {
              num: '1091',
              title: 'Women Safety Helpline',
              desc: 'Specialized 24/7 helpline connecting women in distress with local Women Police stations.',
              badge: 'Dedicated Women Desk',
              color: '#ec4899'
            },
            {
              num: '181',
              title: 'Women in Crisis Helpline',
              desc: 'Support for women facing domestic violence, stalking, sexual harassment, or legal threats.',
              badge: 'Counseling & Rescue',
              color: '#a855f7'
            },
            {
              num: '108',
              title: 'Emergency Medical Service',
              desc: 'Immediate dispatch of ambulances equipped with paramedics and oxygen support.',
              badge: 'Paramedic & ICU',
              color: '#0284c7'
            },
            {
              num: '1098',
              title: 'Childline & Young Girls',
              desc: 'Nationwide emergency helpline for the protection, care, and rescue of children and teens.',
              badge: 'Child Protection',
              color: '#059669'
            },
            {
              num: '1930',
              title: 'Cybercrime & Harassment',
              desc: 'National cyber fraud and online harassment reporting portal for stalking or blackmail.',
              badge: 'Cyber Defense',
              color: '#d97706'
            }
          ].map((item) => (
            <div 
              key={item.num}
              style={{
                background: '#ffffff',
                borderRadius: 'var(--radius-lg)',
                padding: '1.5rem',
                border: '1px solid #e2e8f0',
                boxShadow: 'var(--shadow-sm)',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                gap: '1rem'
              }}
            >
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.6rem' }}>
                  <span style={{ fontSize: '1.6rem', fontWeight: 800, color: item.color }}>{item.num}</span>
                  <span style={{ fontSize: '0.72rem', fontWeight: 700, padding: '0.2rem 0.6rem', borderRadius: 'var(--radius-full)', background: '#f1f5f9', color: 'var(--text-secondary)' }}>
                    {item.badge}
                  </span>
                </div>
                <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '0.4rem' }}>
                  {item.title}
                </h3>
                <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
                  {item.desc}
                </p>
              </div>

              <div style={{ display: 'flex', gap: '0.5rem', paddingTop: '0.75rem', borderTop: '1px solid #f1f5f9' }}>
                <a
                  href={`tel:${item.num}`}
                  style={{
                    flex: 2,
                    background: item.color,
                    color: '#ffffff',
                    padding: '0.55rem',
                    borderRadius: 'var(--radius-md)',
                    fontSize: '0.82rem',
                    fontWeight: 700,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.4rem',
                    textDecoration: 'none'
                  }}
                >
                  <PhoneCall size={14} />
                  <span>Call {item.num}</span>
                </a>

                <button
                  onClick={() => handleCopyNumber(item.num)}
                  title="Copy number to clipboard"
                  style={{
                    flex: 1,
                    background: '#f8fafc',
                    border: '1px solid #cbd5e1',
                    borderRadius: 'var(--radius-md)',
                    color: 'var(--text-secondary)',
                    cursor: 'pointer',
                    fontSize: '0.8rem',
                    fontWeight: 600,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.3rem'
                  }}
                >
                  {copiedHelpline === item.num ? <Check size={14} className="text-emerald" /> : <Copy size={14} />}
                  <span>{copiedHelpline === item.num ? 'Copied' : 'Copy'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 5. PRACTICAL SAFETY PROTOCOLS */}
      <section 
        style={{
          background: 'linear-gradient(135deg, rgba(237, 233, 254, 0.4) 0%, rgba(254, 242, 242, 0.4) 100%)',
          borderRadius: 'var(--radius-xl)',
          padding: 'clamp(1.25rem, 4vw, 2.5rem) clamp(0.75rem, 3vw, 2rem)',
          border: '1px solid rgba(196, 181, 253, 0.4)',
          width: '100%',
          boxSizing: 'border-box'
        }}
      >
        <div style={{ textAlign: 'center', maxWidth: '640px', margin: '0 auto 2rem auto' }}>
          <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#7c3aed', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Empowerment & Preparation
          </span>
          <h2 style={{ fontSize: 'clamp(1.4rem, 4vw, 1.8rem)', fontWeight: 800, color: 'var(--text-primary)', marginTop: '0.3rem' }}>
            4 Golden Rules of Modern Personal Safety
          </h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 220px), 1fr))', gap: '1.25rem', width: '100%', boxSizing: 'border-box' }}>
          <div style={{ background: '#ffffff', padding: '1.5rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0' }}>
            <span style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#ede9fe', color: '#7c3aed', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, marginBottom: '0.8rem' }}>1</span>
            <h4 style={{ fontSize: '0.98rem', fontWeight: 700, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Pre-Enrolled Guardians</h4>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              Never travel alone without at least one verified primary guardian on speed dispatch. Two-way verification ensures they answer immediately.
            </p>
          </div>

          <div style={{ background: '#ffffff', padding: '1.5rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0' }}>
            <span style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#ffe4e6', color: '#e11d48', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, marginBottom: '0.8rem' }}>2</span>
            <h4 style={{ fontSize: '0.98rem', fontWeight: 700, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Hands-Free Safe Phrase</h4>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              In situations where an attacker prevents you from reaching your phone, your vocal safe-phrase silently triggers telemetry without alerting perpetrators.
            </p>
          </div>

          <div style={{ background: '#ffffff', padding: '1.5rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0' }}>
            <span style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#dcfce7', color: '#059669', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, marginBottom: '0.8rem' }}>3</span>
            <h4 style={{ fontSize: '0.98rem', fontWeight: 700, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Sanctuary Navigation</h4>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              Familiarize yourself with community safe havens (24/7 convenience stores, fuel stations, lit transit hubs) along your daily commute routes.
            </p>
          </div>

          <div style={{ background: '#ffffff', padding: '1.5rem', borderRadius: 'var(--radius-lg)', border: '1px solid #e2e8f0' }}>
            <span style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#e0f2fe', color: '#0284c7', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, marginBottom: '0.8rem' }}>4</span>
            <h4 style={{ fontSize: '0.98rem', fontWeight: 700, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Medical Readiness</h4>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              Having your blood group and emergency medical alerts pre-attached to your rescue dossier saves life-critical minutes for first responders.
            </p>
          </div>
        </div>
      </section>

      {/* 6. ETHICAL PRIVACY & DATA SOVEREIGNTY PLEDGE */}
      <section 
        style={{
          background: '#ffffff',
          borderRadius: 'var(--radius-xl)',
          padding: '2.5rem 2rem',
          border: '1px solid #e2e8f0',
          boxShadow: 'var(--shadow-sm)'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', marginBottom: '1.25rem' }}>
          <ShieldCheck size={28} className="text-emerald" />
          <div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              Our Uncompromised Data Sovereignty Pledge
            </h3>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
              Built strictly to protect women — never to track, monetize, or profile.
            </span>
          </div>
        </div>

        <div className="helpline-directory-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 260px), 1fr))', gap: '1.25rem', width: '100%', boxSizing: 'border-box' }}>
          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <CheckCircle2 size={18} className="text-emerald" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <strong style={{ fontSize: '0.9rem', color: 'var(--text-primary)', display: 'block' }}>Zero Continuous Tracking</strong>
              <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                Your GPS coordinates are never polled or stored during ordinary activities. Real-time telemetry is engaged only when you activate SOS.
              </p>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <CheckCircle2 size={18} className="text-emerald" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <strong style={{ fontSize: '0.9rem', color: 'var(--text-primary)', display: 'block' }}>Cryptographic Password Shield</strong>
              <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                Account credentials and secret phrases are protected with memory-hard cryptographic algorithms that cannot be reverse-engineered.
              </p>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <CheckCircle2 size={18} className="text-emerald" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <strong style={{ fontSize: '0.9rem', color: 'var(--text-primary)', display: 'block' }}>Strict Private Tenant Isolation</strong>
              <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                Your emergency contact list, safe routes, and incident logs are mathematically partitioned so only you and verified contacts have access.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 7. BOTTOM CALL TO ACTION */}
      <section 
        style={{
          background: 'linear-gradient(135deg, #7c3aed 0%, #ec4899 50%, #f43f5e 100%)',
          borderRadius: 'var(--radius-xl)',
          padding: 'clamp(2rem, 5vw, 3rem) clamp(1rem, 3vw, 2rem)',
          textAlign: 'center',
          color: '#ffffff',
          boxShadow: 'var(--shadow-glow-indigo)',
          width: '100%',
          boxSizing: 'border-box'
        }}
      >
        <h2 style={{ fontSize: 'clamp(1.5rem, 4.5vw, 2rem)', fontWeight: 800, marginBottom: '0.8rem' }}>
          Your Life. Your Freedom. 100% Protected.
        </h2>
        <p style={{ fontSize: 'clamp(0.92rem, 2.5vw, 1.05rem)', maxWidth: '640px', margin: '0 auto 2rem auto', opacity: 0.95, lineHeight: 1.6 }}>
          Join thousands of women who navigate with complete confidence. Set up your guardian lifeline and emergency police dossier in under 2 minutes.
        </p>

        <button 
          id="btn-bottom-cta-register"
          onClick={() => onOpenAuth('register')}
          style={{
            background: '#ffffff',
            color: '#7c3aed',
            border: 'none',
            borderRadius: 'var(--radius-full)',
            padding: '0.9rem 1.8rem',
            fontSize: '1rem',
            fontWeight: 800,
            cursor: 'pointer',
            boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
            transition: 'var(--transition-smooth)',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.6rem',
            maxWidth: '100%',
            whiteSpace: 'normal'
          }}
        >
          <Shield size={20} />
          <span>Create Your Protected Profile Now</span>
          <ArrowRight size={18} />
        </button>
      </section>
    </div>
  );
};