const express = require('express');
const router = express.Router();
const { giveFeedback, getProposalsByDosen, getProposalHistory } = require('../controllers/pembimbingController');
const { verifyDosen } = require('../middleware/auth');

router.post('/feedback', verifyDosen, giveFeedback);          // Dosen beri feedback
router.get('/proposals', verifyDosen, getProposalsByDosen);   // Dosen lihat proposal bimbingan
router.get('/proposal-history/:id', verifyDosen, getProposalHistory); // Riwayat proposal

module.exports = router;
