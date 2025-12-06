const express = require('express');
const router = express.Router();
const { 
  loginAdmin, 
  addDosen, 
  getAllDosenWithStatus, 
  getAllMahasiswaWithStatus, 
  getAllProposal, 
  assignPembimbing,
  getDashboardStatistics,
  removePembimbing,
  searchProposals
} = require('../controllers/adminController');
const { verifyAdmin } = require('../middleware/auth');

// Login admin (tanpa auth)
router.post('/login', loginAdmin);

// Endpoint yang butuh verifikasi admin
router.get('/dashboard', verifyAdmin, getDashboardStatistics);   // Dashboard statistics
router.get('/dosen', verifyAdmin, getAllDosenWithStatus);        // list dosen dengan status pembimbing
router.get('/mahasiswa', verifyAdmin, getAllMahasiswaWithStatus); // list mahasiswa dengan status proposal
router.get('/proposal', verifyAdmin, getAllProposal);            // list semua proposal
router.get('/search-proposals', verifyAdmin, searchProposals);   // search proposal dengan filter
router.post('/dosen', verifyAdmin, addDosen);                    // tambah dosen
router.post('/assign-pembimbing', verifyAdmin, assignPembimbing); // assign pembimbing ke proposal
router.delete('/remove-pembimbing', verifyAdmin, removePembimbing); // remove pembimbing dari proposal

module.exports = router;
