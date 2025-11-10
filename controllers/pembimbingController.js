const conn = require('../config/db');

const assignPembimbing = (req, res) => {
  const { proposal_id, dosen_id, jenis } = req.body;
  const query = `CALL sp_assign_pembimbing(?, ?, ?);`;
  conn.query(query, [proposal_id, dosen_id, jenis], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Pembimbing berhasil diberikan' });
  });
};

const giveFeedback = (req, res) => {
  const { proposal_id, dosen_id, feedback, new_status_id } = req.body;
  const query = `CALL sp_give_feedback(?, ?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [proposal_id, dosen_id, feedback, new_status_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const getProposalsByDosen = (req, res) => {
  const { dosen_id } = req.params;
  const query = `CALL sp_get_proposal_bimbingan(?);`;
  conn.query(query, [dosen_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
};

module.exports = { assignPembimbing, giveFeedback, getProposalsByDosen };
