const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { prisma } = require('../config/database');
const { jwtSecret, jwtExpiresIn } = require('../config');

const SALT_ROUNDS = 10;

class AuthController {
  async register(req, res) {
    try {
      const { email, password, nickname } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Email and password are required'
        });
      }

      if (password.length < 6) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Password must be at least 6 characters'
        });
      }

      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Invalid email format'
        });
      }

      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        return res.status(409).json({
          error: 'Conflict',
          message: 'Email already registered'
        });
      }

      const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

      const user = await prisma.user.create({
        data: {
          email,
          passwordHash,
          nickname: nickname || email.split('@')[0]
        }
      });

      const token = jwt.sign(
        { userId: user.id, email: user.email, isAdmin: user.isAdmin },
        jwtSecret,
        { expiresIn: jwtExpiresIn }
      );

      res.status(201).json({
        message: 'User registered successfully',
        token,
        user: {
          id: user.id,
          email: user.email,
          nickname: user.nickname,
          balance: user.balance
        }
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Registration failed'
      });
    }
  }

  async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Email and password are required'
        });
      }

      const user = await prisma.user.findUnique({
        where: { email }
      });

      if (!user) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'Invalid email or password'
        });
      }

      if (!user.isActive) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'Account is disabled'
        });
      }

      const isValidPassword = await bcrypt.compare(password, user.passwordHash);

      if (!isValidPassword) {
        return res.status(401).json({
          error: 'Unauthorized',
          message: 'Invalid email or password'
        });
      }

      const token = jwt.sign(
        { userId: user.id, email: user.email, isAdmin: user.isAdmin },
        jwtSecret,
        { expiresIn: jwtExpiresIn }
      );

      res.json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          email: user.email,
          nickname: user.nickname,
          balance: user.balance
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Login failed'
      });
    }
  }

  async getProfile(req, res) {
    try {
      const userId = req.user.userId;

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          nickname: true,
          balance: true,
          isAdmin: true,
          createdAt: true
        }
      });

      if (!user) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'User not found'
        });
      }

      res.json({ user });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to get profile'
      });
    }
  }

  async updateProfile(req, res) {
    try {
      const userId = req.user.userId;
      const { nickname } = req.body;

      const user = await prisma.user.update({
        where: { id: userId },
        data: { nickname },
        select: {
          id: true,
          email: true,
          nickname: true,
          balance: true,
          isAdmin: true
        }
      });

      res.json({
        message: 'Profile updated successfully',
        user
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update profile'
      });
    }
  }
}

module.exports = new AuthController();
