const express = require('express');
const router = express.Router();
const { submitProposal, deleteProposalSP, getProposalDetail, editProposal } = require('../controllers/proposalController');
const { verifyMahasiswa } = require('../middleware/auth');

// Semua endpoint proposal butuh authentication mahasiswa
router.post('/', verifyMahasiswa, submitProposal);           // POST /api/proposal (submit baru)
router.get('/:id', verifyMahasiswa, getProposalDetail);      // GET /api/proposal/:id (detail)
router.put('/:id', verifyMahasiswa, editProposal);           // PUT /api/proposal/:id (update)
router.delete('/:id', verifyMahasiswa, deleteProposalSP);    // DELETE /api/proposal/:id (hapus)

module.exports = router;
