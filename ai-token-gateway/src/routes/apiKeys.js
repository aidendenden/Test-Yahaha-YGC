const express = require('express');
const router = express.Router();
const apiKeyController = require('../controllers/apiKeyController');
const { authenticateJwt } = require('../middleware/auth');

router.post('/', authenticateJwt, apiKeyController.create);
router.get('/', authenticateJwt, apiKeyController.list);
router.delete('/:id', authenticateJwt, apiKeyController.delete);
router.put('/:id/status', authenticateJwt, apiKeyController.updateStatus);

module.exports = router;
