const conn = require('../config/db');

const submitProposal = (req, res) => {
  const mahasiswa_id = req.user.id;
  const { judul, abstrak, catatan } = req.body;

  const query = 'CALL sp_submit_proposal(?, ?, ?, ?, @proposal_id, @message); SELECT @proposal_id AS proposal_id, @message AS message;';
  conn.query(query, [mahasiswa_id, judul, abstrak, catatan], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const deleteProposalSP = (req, res) => {
  const proposal_id = req.params.id;
  const mahasiswa_id = req.user.id; // otomatis dari token
  
  const query = 'CALL sp_delete_proposal(?, ?, @message); SELECT @message AS message;';
  conn.query(query, [proposal_id, mahasiswa_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const editProposal = (req, res) => {
  const proposal_id = req.params.id;
  const mahasiswa_id = req.user.id; // otomatis dari token
  const { judul, abstrak, catatan } = req.body;
  
  const query = 'CALL sp_edit_proposal(?, ?, ?, ?, ?, @message); SELECT @message AS message;';
  conn.query(query, [proposal_id, mahasiswa_id, judul, abstrak, catatan], (err, results) => {
    if (err) return res.status(500).json({ message: 'Error DB' });
    const output = results[1][0];
    res.json(output);
  });
};

const getProposalDetail = (req, res) => {
  const proposalId = req.params.id;
  const query = 'CALL sp_get_proposal_detail(?);';
  conn.query(query, [proposalId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results[0].length === 0) {
      return res.status(404).json({ message: 'Proposal tidak ditemukan' });
    }
    res.json(results[0][0]);
  });
};

module.exports = { submitProposal, editProposal, deleteProposalSP, getProposalDetail };
