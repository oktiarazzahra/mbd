const express = require('express');
const router = express.Router();
const { submitProposal, deleteProposalSP, getProposalDetail, editProposal } = require('../controllers/proposalController');

router.post('/submit', submitProposal);
router.put('/edit', editProposal);
router.delete('/delete', deleteProposalSP);
router.get('/detail/:id', getProposalDetail);  
module.exports = router;
