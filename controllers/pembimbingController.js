const conn = require('../config/db');

const giveFeedback = (req, res) => {
  const dosen_id = req.user.id; // otomatis dari token dosen
  const { proposal_id, feedback, new_status_id } = req.body;
  const query = `CALL sp_give_feedback(?, ?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [proposal_id, dosen_id, feedback, new_status_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const getProposalsByDosen = (req, res) => {
  const dosen_id = req.user.id; // otomatis dari token dosen, tidak perlu di params
  const query = `CALL sp_get_proposal_bimbingan(?);`;
  conn.query(query, [dosen_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
};

module.exports = { giveFeedback, getProposalsByDosen };
