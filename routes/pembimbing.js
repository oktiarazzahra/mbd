const express = require('express');
const router = express.Router();
const { giveFeedback, getProposalsByDosen } = require('../controllers/pembimbingController');
const { verifyDosen } = require('../middleware/auth');

router.post('/feedback', verifyDosen, giveFeedback);     // Dosen beri feedback
router.get('/proposals', verifyDosen, getProposalsByDosen); // Dosen lihat proposal bimbingan (tidak perlu :dosen_id lagi)

module.exports = router;
