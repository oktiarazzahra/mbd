const express = require('express');
const router = express.Router();
const { 
  loginDosen, 
  getStatistics, 
  updateProfile, 
  changePassword 
} = require('../controllers/dosenController');
const { verifyDosen } = require('../middleware/auth');

// Public endpoint
router.post('/login', loginDosen);

// Protected endpoints (require authentication)
router.get('/statistics', verifyDosen, getStatistics);         // GET /api/dosen/statistics - Statistik dosen
router.put('/profile', verifyDosen, updateProfile);            // PUT /api/dosen/profile - Update profil
router.put('/change-password', verifyDosen, changePassword);   // PUT /api/dosen/change-password - Ganti password

module.exports = router;
