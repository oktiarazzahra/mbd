const express = require('express');
const router = express.Router();
const { loginAdmin, addDosen, getAllDosenWithStatus, getAllMahasiswaWithStatus, getAllProposal, assignPembimbing } = require('../controllers/adminController');
const { verifyAdmin } = require('../middleware/auth');

// Login admin (tanpa auth)
router.post('/login', loginAdmin);

// Endpoint yang butuh verifikasi admin
router.get('/dosen', verifyAdmin, getAllDosenWithStatus);      // list dosen dengan status pembimbing
router.get('/mahasiswa', verifyAdmin, getAllMahasiswaWithStatus); // list mahasiswa dengan status proposal
router.get('/proposal', verifyAdmin, getAllProposal);            // list semua proposal
router.post('/dosen', verifyAdmin, addDosen);             // tambah dosen
router.post('/assign-pembimbing', verifyAdmin, assignPembimbing); // assign pembimbing ke proposal

module.exports = router;
