const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateJwt } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/profile', authenticateJwt, authController.getProfile);
router.put('/profile', authenticateJwt, authController.updateProfile);

module.exports = router;
