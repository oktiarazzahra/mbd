const conn = require('../config/db');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

const loginDosen = (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ message: 'Email dan password wajib diisi' });
  }
  
  const queryLogin = `CALL sp_login_dosen(?, ?, @message); SELECT @message AS message;`;
  conn.query(queryLogin, [email, password], (err, results) => {
    if (err) return res.status(400).json({ message: err.message });
    
    const output = results[1][0];
    
    if (!output || output.message.includes('gagal') || output.message.includes('tidak')) {
      return res.status(401).json({ message: output?.message || 'Login gagal' });
    }
    
    const queryGetData = `SELECT dosen_id, nip, nama, email, bidang_keahlian FROM dosen WHERE email = ?`;
    conn.query(queryGetData, [email], (err2, userData) => {
      if (err2) return res.status(400).json({ message: err2.message });
      
      if (userData.length === 0) {
        return res.status(404).json({ message: 'Data dosen tidak ditemukan' });
      }
      
      const dosen = userData[0];
      
      const token = jwt.sign(
        {
          id: dosen.dosen_id,
          nip: dosen.nip,
          nama: dosen.nama,
          email: dosen.email,
          bidang_keahlian: dosen.bidang_keahlian,
          role: 'dosen'
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      res.json({
        message: 'Login berhasil',
        token: token,
        user: {
          dosen_id: dosen.dosen_id,
          nip: dosen.nip,
          nama: dosen.nama,
          email: dosen.email,
          bidang_keahlian: dosen.bidang_keahlian,
          role: 'dosen'
        }
      });
    });
  });
};

// Get statistik dosen
const getStatistics = (req, res) => {
  const dosen_id = req.user.id; // dari JWT token
  
  const query = `CALL sp_get_dosen_statistics(?);`;
  conn.query(query, [dosen_id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    
    if (results[0].length === 0) {
      return res.status(404).json({ message: 'Data dosen tidak ditemukan' });
    }
    res.json(results[0][0]);
  });
};

// Update profil dosen
const updateProfile = (req, res) => {
  const dosen_id = req.user.id;
  const { nama, bidang_keahlian } = req.body;
  
  if (!nama || !bidang_keahlian) {
    return res.status(400).json({ message: 'Nama dan bidang keahlian wajib diisi' });
  }
  
  const query = `CALL sp_update_dosen_profile(?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [dosen_id, nama, bidang_keahlian], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    res.json(output);
  });
};

// Change password dosen
const changePassword = (req, res) => {
  const dosen_id = req.user.id;
  const { old_password, new_password } = req.body;
  
  if (!old_password || !new_password) {
    return res.status(400).json({ message: 'Password lama dan baru wajib diisi' });
  }
  
  const query = `CALL sp_change_password_dosen(?, ?, ?, @message); SELECT @message AS message;`;
  conn.query(query, [dosen_id, old_password, new_password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1][0];
    
    if (output.message.includes('Error')) {
      return res.status(400).json(output);
    }
    res.json(output);
  });
};

module.exports = { loginDosen, getStatistics, updateProfile, changePassword };
