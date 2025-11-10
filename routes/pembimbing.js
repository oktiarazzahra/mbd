const express = require('express');
const router = express.Router();
const { assignPembimbing, giveFeedback, getProposalsByDosen } = require('../controllers/pembimbingController');

router.post('/assign', assignPembimbing);
router.post('/feedback', giveFeedback);
router.get('/proposals/:dosen_id', getProposalsByDosen);

module.exports = router;
