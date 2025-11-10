const conn = require('../config/db');

const registerDosen = (req, res) => {
  const { nip, nama, email, bidang_keahlian } = req.body;

  const query = `CALL sp_register_dosen(?, ?, ?, ?, @dosen_id, @message); SELECT @dosen_id AS dosen_id, @message AS message;`;
  conn.query(query, [nip, nama, email, bidang_keahlian], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const loginDosen = (req, res) => {
  const { email, password } = req.body;

  const query = `CALL sp_login_dosen(?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [email, password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

module.exports = { registerDosen, loginDosen };
