const conn = require('../config/db');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

const registerMahasiswa = (req, res) => {
  const { nim, nama, email, password, prodi, angkatan } = req.body;
  const query = `CALL sp_register_mahasiswa(?, ?, ?, ?, ?, ?, @mahasiswa_id, @message); SELECT @mahasiswa_id AS mahasiswa_id, @message AS message;`;
  conn.query(query, [nim, nama, email, password, prodi, angkatan], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.status(201).json(output);
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

// Get semua proposal milik mahasiswa yang login
const getMyProposals = (req, res) => {
  const mahasiswa_id = req.user.id; // dari JWT token
  
  const query = `CALL sp_get_mahasiswa_proposals(?);`;
  conn.query(query, [mahasiswa_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
};

// Get profile mahasiswa
const getProfile = (req, res) => {
  const mahasiswa_id = req.user.id;
  
  const query = `SELECT mahasiswa_id, nim, nama, email, prodi, angkatan FROM mahasiswa WHERE mahasiswa_id = ?`;
  conn.query(query, [mahasiswa_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ message: 'Mahasiswa tidak ditemukan' });
    }
    
    res.json(results[0]);
  });
};

// Update profil mahasiswa
const updateProfile = (req, res) => {
  const mahasiswa_id = req.user.id;
  const { nama, prodi } = req.body;
  
  if (!nama || !prodi) {
    return res.status(400).json({ message: 'Nama dan prodi wajib diisi' });
  }
  
  const query = `CALL sp_update_mahasiswa_profile(?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [mahasiswa_id, nama, prodi], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

// Change password mahasiswa
const changePassword = (req, res) => {
  const mahasiswa_id = req.user.id;
  const { old_password, new_password } = req.body;
  
  if (!old_password || !new_password) {
    return res.status(400).json({ message: 'Password lama dan baru wajib diisi' });
  }
  
  const query = `CALL sp_change_password_mahasiswa(?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [mahasiswa_id, old_password, new_password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    
    if (output.message.includes('Error')) {
      return res.status(400).json(output);
    }
    res.json(output);
  });
};

module.exports = { registerMahasiswa, loginMahasiswa, getMyProposals, getProfile, updateProfile, changePassword };
