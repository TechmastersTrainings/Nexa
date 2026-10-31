import React, { useState, useEffect } from 'react';
import { Shield, LogOut, User, Activity } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api/client';
import type { HealthStatus } from '../api/client';

interface NavbarProps {
  onOpenAuth: (mode: 'login' | 'register') => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onOpenAuth }) => {
  const { user, token, logout } = useAuth();
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [isHealthOnline, setIsHealthOnline] = useState<boolean>(false);

  useEffect(() => {
    const fetchHealth = async () => {
      try {
        const data = await api.checkHealth();
        setHealth(data);
        setIsHealthOnline(data.status === 'healthy' && data.database === 'connected');
      } catch (e) {
        setIsHealthOnline(false);
      }
    };

    fetchHealth();
    const interval = setInterval(fetchHealth, 15000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="navbar-container">
      <div className="navbar-inner">
        {/* Brand Logo */}
        <div className="brand-group">
          <div className="logo-shield">
            <Shield className="shield-icon" size={24} />
            <span className="shield-pulse"></span>
          </div>
          <div>
            <div className="brand-title">
              <span className="brand-nexa">NEXA</span>
              <span className="brand-tag">AI SAFETY</span>
            </div>
            <div className="brand-subtitle">Intelligent Guardian Network</div>
          </div>
        </div>

        {/* Live System Health Pill */}
        <div className="health-pill" title={health ? `Connected to ${health.database} database` : 'Connecting...'}>
          <span className={`status-dot ${isHealthOnline ? 'online' : 'offline'}`}></span>
          <span className="health-text">
            {isHealthOnline ? 'NETWORK SECURE • SENTINEL ACTIVE' : 'CONNECTING SECURE NETWORK...'}
          </span>
          <Activity size={14} className="health-icon" />
        </div>

        {/* Navigation Action Area */}
        <div className="nav-actions">
          {token && user ? (
            <div className="user-nav-box">
              <div className="user-avatar-badge">
                <User size={16} />
              </div>
              <div className="user-meta">
                <span className="user-name">{user.full_name}</span>
                <span className="user-role">Guardian Account</span>
              </div>
              <button 
                id="btn-logout"
                className="btn-logout" 
                onClick={logout}
                title="Sign out of companion dashboard"
              >
                <LogOut size={16} />
                <span>Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="auth-btn-group">
              <button 
                id="btn-nav-login"
                className="btn-ghost" 
                onClick={() => onOpenAuth('login')}
              >
                Sign In
              </button>
              <button 
                id="btn-nav-register"
                className="btn-primary" 
                onClick={() => onOpenAuth('register')}
              >
                Get Protected
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
