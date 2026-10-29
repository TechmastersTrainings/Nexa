import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api/client';
import type { UserProfile } from '../api/client';

interface AuthContextType {
  token: string | null;
  user: UserProfile | null;
  isLoading: boolean;
  error: string | null;
  login: (usernameOrEmail: string, password: string) => Promise<void>;
  register: (data: { email: string; password: string; full_name: string; phone_number: string }) => Promise<void>;
  logout: () => void;
  clearError: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('nexa_token'));
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const clearError = () => setError(null);

  const refreshProfile = async () => {
    if (!token) {
      setUser(null);
      setIsLoading(false);
      return;
    }
    try {
      const profile = await api.getMe(token);
      setUser(profile);
    } catch (err: any) {
      console.warn('Session expired or invalid:', err.message);
      logout();
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    refreshProfile();
  }, [token]);

  const login = async (usernameOrEmail: string, password: string) => {
    setIsLoading(true);
    setError(null);
    try {
      const auth = await api.login(usernameOrEmail, password);
      localStorage.setItem('nexa_token', auth.access_token);
      setToken(auth.access_token);
      const profile = await api.getMe(auth.access_token);
      setUser(profile);
    } catch (err: any) {
      setError(err.message || 'Login failed');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (data: { email: string; password: string; full_name: string; phone_number: string }) => {
    setIsLoading(true);
    setError(null);
    try {
      await api.register(data);
      // Auto-login after registration
      await login(data.email, data.password);
    } catch (err: any) {
      setError(err.message || 'Registration failed');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('nexa_token');
    setToken(null);
    setUser(null);
    setError(null);
  };

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        isLoading,
        error,
        login,
        register,
        logout,
        clearError,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return ctx;
};
