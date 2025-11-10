const conn = require('../config/db');

const registerMahasiswa = (req, res) => {
  const { nim, nama, email, password, prodi, angkatan } = req.body;
  const query = `CALL sp_register_mahasiswa(?, ?, ?, ?, ?, ?, @mahasiswa_id, @message); SELECT @mahasiswa_id AS mahasiswa_id, @message AS message;`;
  conn.query(query, [nim, nama, email, password, prodi, angkatan], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

const loginMahasiswa = (req, res) => {
  const { email, password } = req.body;
  const query = `CALL sp_login_mahasiswa(?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [email, password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

module.exports = { registerMahasiswa, loginMahasiswa };
