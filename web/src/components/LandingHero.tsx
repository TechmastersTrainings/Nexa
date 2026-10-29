import React from 'react';
import { Mic, Radio, Lock, ArrowRight, HeartHandshake } from 'lucide-react';

interface LandingHeroProps {
  onOpenAuth: (mode: 'login' | 'register') => void;
}

export const LandingHero: React.FC<LandingHeroProps> = ({ onOpenAuth }) => {
  return (
    <div className="landing-container animate-fade-in">
      {/* Hero Header */}
      <section className="hero-section">
        <div className="hero-pill">
          <span className="hero-pill-dot"></span>
          <span>RESEARCH-BACKED WOMEN SAFETY PLATFORM</span>
        </div>

        <h1 className="hero-heading">
          Intelligent AI Safety Guardian <br />
          <span className="text-gradient">Engineered for Zero Compromise.</span>
        </h1>

        <p className="hero-description">
          A dual-component safety system combining native offline on-device speech intelligence with a secure cloud companion dashboard. Built to defend when every millisecond counts.
        </p>

        <div className="hero-actions">
          <button 
            id="btn-hero-register"
            className="btn-hero-primary" 
            onClick={() => onOpenAuth('register')}
          >
            <span>Create Guardian Account</span>
            <ArrowRight size={18} />
          </button>

          <button 
            id="btn-hero-login"
            className="btn-hero-secondary" 
            onClick={() => onOpenAuth('login')}
          >
            <span>Access Web Console</span>
          </button>
        </div>
      </section>

      {/* Feature Pillar Cards */}
      <section className="feature-grid">
        <div className="feature-card">
          <div className="feature-icon-badge bg-indigo-glow">
            <Mic size={24} className="text-indigo" />
          </div>
          <h2 className="feature-title">Offline Voice Trigger</h2>
          <p className="feature-text">
            On-device Vosk speech engine running locally on Android. Recognizes distress keywords like "Help" or "Bachao" without requiring active internet connectivity.
          </p>
        </div>

        <div className="feature-card">
          <div className="feature-icon-badge bg-rose-glow">
            <Radio size={24} className="text-rose" />
          </div>
          <h2 className="feature-title">Local Incident Queue</h2>
          <p className="feature-text">
            Never drops an emergency event. Incidents, audio snippets, and GPS telemetry are cached in local encrypted storage and flushed immediately once connectivity resumes.
          </p>
        </div>

        <div className="feature-card">
          <div className="feature-icon-badge bg-emerald-glow">
            <HeartHandshake size={24} className="text-emerald" />
          </div>
          <h2 className="feature-title">Verified Responder Network</h2>
          <p className="feature-text">
            Multi-tiered emergency contact escalation. Contacts are verified via two-way handshake to eliminate incorrect dispatch and ensure reliable rescue coordination.
          </p>
        </div>

        <div className="feature-card">
          <div className="feature-icon-badge bg-cyan-glow">
            <Lock size={24} className="text-cyan" />
          </div>
          <h2 className="feature-title">Argon2id & Row Isolation</h2>
          <p className="feature-text">
            State-of-the-art cryptographic safeguards protect user personal data, emergency lists, and location traces with strict row-level authorization boundaries.
          </p>
        </div>
      </section>
    </div>
  );
};
