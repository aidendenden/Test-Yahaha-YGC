import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authAPI = {
  register: (data) => api.post('/api/auth/register', data),
  login: (data) => api.post('/api/auth/login', data),
  getProfile: () => api.get('/api/auth/profile'),
  updateProfile: (data) => api.put('/api/auth/profile', data),
};

export const apiKeysAPI = {
  create: (data) => api.post('/api/keys', data),
  list: () => api.get('/api/keys'),
  delete: (id) => api.delete(`/api/keys/${id}`),
  updateStatus: (id, data) => api.put(`/api/keys/${id}/status`, data),
};

export const usageAPI = {
  getSummary: (params) => api.get('/api/usage/summary', { params }),
  getDetails: (params) => api.get('/api/usage/details', { params }),
  getBalance: () => api.get('/api/balance/balance'),
  recharge: (data) => api.post('/api/balance/recharge', data),
};

export const modelsAPI = {
  list: () => api.get('/v1/models'),
};

export default api;
