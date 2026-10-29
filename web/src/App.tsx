import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Navbar } from './components/Navbar';
import { LandingHero } from './components/LandingHero';
import { Dashboard } from './components/Dashboard';
import { AuthModal } from './components/AuthModal';
import { Loader2 } from 'lucide-react';
import './App.css';

const AppContent: React.FC = () => {
  const { user, token, isLoading } = useAuth();
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'register'>('login');

  const handleOpenAuth = (mode: 'login' | 'register') => {
    setAuthModalMode(mode);
    setAuthModalOpen(true);
  };

  return (
    <div className="app-shell">
      <Navbar onOpenAuth={handleOpenAuth} />

      <main className="main-content">
        {isLoading && !user && token ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: '1rem' }}>
            <Loader2 size={36} className="spin-icon text-indigo" />
            <span style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Verifying secure session...</span>
          </div>
        ) : token && user ? (
          <Dashboard />
        ) : (
          <LandingHero onOpenAuth={handleOpenAuth} />
        )}
      </main>

      <AuthModal
        isOpen={authModalOpen}
        initialMode={authModalMode}
        onClose={() => setAuthModalOpen(false)}
      />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
};

export default App;
