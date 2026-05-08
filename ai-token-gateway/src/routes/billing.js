const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { authenticateJwt } = require('../middleware/auth');

router.get('/summary', authenticateJwt, billingController.getUsageSummary);
router.get('/details', authenticateJwt, billingController.getUsageDetails);
router.get('/balance', authenticateJwt, billingController.getBalance);
router.post('/recharge', authenticateJwt, billingController.recharge);

module.exports = router;
