const express = require('express');
const router = express.Router();
const { 
  registerMahasiswa, 
  loginMahasiswa, 
  getMyProposals, 
  getProfile,
  updateProfile, 
  changePassword 
} = require('../controllers/mahasiswaController');
const { verifyMahasiswa } = require('../middleware/auth');

// Public endpoints
router.post('/register', registerMahasiswa);
router.post('/login', loginMahasiswa);

// Protected endpoints (require authentication)
router.get('/proposals', verifyMahasiswa, getMyProposals);        // GET /api/mahasiswa/proposals - List proposal milik mahasiswa
router.get('/profile', verifyMahasiswa, getProfile);              // GET /api/mahasiswa/profile - Get profil
router.put('/profile', verifyMahasiswa, updateProfile);           // PUT /api/mahasiswa/profile - Update profil
router.put('/change-password', verifyMahasiswa, changePassword);  // PUT /api/mahasiswa/change-password - Ganti password

module.exports = router;
