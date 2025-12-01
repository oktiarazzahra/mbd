const conn = require('../config/db');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

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
  
  // Cek kredensial dulu
  const queryLogin = `CALL sp_login_mahasiswa(?, ?, @message); SELECT @message AS message;`;
  conn.query(queryLogin, [email, password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    
    const output = results[1][0];
    
    // Jika login gagal
    if (!output || output.message.includes('gagal') || output.message.includes('tidak')) {
      return res.status(401).json(output);
    }
    
    // Login berhasil, ambil data mahasiswa
    const queryGetData = `SELECT mahasiswa_id, nim, nama, email FROM mahasiswa WHERE email = ?`;
    conn.query(queryGetData, [email], (err2, userData) => {
      if (err2) return res.status(500).json({ error: err2.message });
      
      if (userData.length === 0) {
        return res.status(404).json({ message: 'Data mahasiswa tidak ditemukan' });
      }
      
      const mahasiswa = userData[0];
      
      // Generate JWT token
      const token = jwt.sign(
        {
          id: mahasiswa.mahasiswa_id,
          nim: mahasiswa.nim,
          nama: mahasiswa.nama,
          email: mahasiswa.email,
          role: 'mahasiswa'
        },
        JWT_SECRET,
        { expiresIn: '1h' } // Token berlaku 1 jam
      );
      
      res.json({
        message: 'Login berhasil',
        token: token,
        user: {
          mahasiswa_id: mahasiswa.mahasiswa_id,
          nim: mahasiswa.nim,
          nama: mahasiswa.nama,
          email: mahasiswa.email,
          role: 'mahasiswa'
        }
      });
    });
  });
};

module.exports = { registerMahasiswa, loginMahasiswa };
