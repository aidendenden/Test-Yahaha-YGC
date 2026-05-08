const express = require('express');
const router = express.Router();
const proxyController = require('../controllers/proxyController');
const { authenticateApiKey } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');

router.use(authenticateApiKey);
router.use(apiLimiter);

router.post('/chat/completions', proxyController.chatCompletion);
router.post('/embeddings', proxyController.embeddings);
router.get('/models', proxyController.listModels);

module.exports = router;
