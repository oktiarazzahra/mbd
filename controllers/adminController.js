const conn = require('../config/db');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

// Admin login menggunakan stored procedure
const loginAdmin = (req, res) => {
  const { username, password } = req.body;
  
  // Panggil stored procedure login admin
  const queryLogin = `CALL sp_login_admin(?, ?, @admin_id, @message); SELECT @admin_id AS admin_id, @message AS message;`;
  conn.query(queryLogin, [username, password], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    
    const output = results[1][0];
    
    // Jika login gagal (admin_id null atau message error)
    if (!output || !output.admin_id || output.message.includes('gagal') || output.message.includes('tidak')) {
      return res.status(401).json({ message: output?.message || 'Login admin gagal' });
    }
    
    // Login berhasil, generate JWT token
    const token = jwt.sign(
      {
        id: output.admin_id,
        username: username,
        role: 'admin'
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      message: 'Login admin berhasil',
      token: token,
      user: {
        admin_id: output.admin_id,
        username: username,
        role: 'admin'
      }
    });
  });
};

// Admin: Menambahkan Dosen
const addDosen = (req, res) => {
  const { nip, nama, email, password, bidang_keahlian } = req.body;
  const query = `CALL sp_register_dosen(?, ?, ?, ?, ?, @dosen_id, @message); SELECT @dosen_id AS dosen_id, @message AS message;`;
  conn.query(query, [nip, nama, email, password, bidang_keahlian], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const output = results[1] && results[1][0] ? results[1][0] : { dosen_id: null, message: null };
    res.json(output);
  });
};

// Admin: Melihat semua dosen dengan status pembimbing
const getAllDosenWithStatus = (req, res) => {
  const query = 'CALL sp_admin_view_all_dosen();';

  conn.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    // results[0] = hasil SELECT di dalam procedure
    res.json(results[0]);
  });
};

// Admin: Melihat semua mahasiswa dengan status proposal
const getAllMahasiswaWithStatus = (req, res) => {
  const query = 'CALL sp_admin_view_all_mahasiswa();';

  conn.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    res.json(results[0]);
  });
};

// Admin: Melihat semua proposal
const getAllProposal = (req, res) => {
  const query = 'CALL sp_admin_view_all_proposal();';

  conn.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    res.json(results[0]);
  });
};

// Admin: Assign pembimbing ke proposal (dengan validasi keberadaan ID)
const assignPembimbing = (req, res) => {
  const { proposal_id, dosen_id, jenis } = req.body;
  const query = 'CALL sp_assign_pembimbing(?, ?, ?, @p_message); SELECT @p_message AS message;';
  conn.query(query, [proposal_id, dosen_id, jenis], (err3, results) => {
    if (err3) {
      return res.status(500).json({ error: err3.message });
    }
    const out = results && results[1] && results[1][0] ? results[1][0] : { message: null };
    res.json(out);
  });
};

// Admin: Get dashboard statistics
const getDashboardStatistics = (req, res) => {
  const query = 'CALL sp_get_dashboard_statistics();';
  
  conn.query(query, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0][0]);
  });
};

// Admin: Remove pembimbing dari proposal
const removePembimbing = (req, res) => {
  const { proposal_id, dosen_id } = req.body;
  
  if (!proposal_id || !dosen_id) {
    return res.status(400).json({ message: 'proposal_id dan dosen_id wajib diisi' });
  }
  
  const query = 'CALL sp_remove_pembimbing(?, ?, @message); SELECT @message AS message;';
  conn.query(query, [proposal_id, dosen_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    const output = results && results[1] && results[1][0] ? results[1][0] : { message: null };
    res.json(output);
  });
};

// Admin: Search proposals dengan filter
const searchProposals = (req, res) => {
  const { keyword, status_id, mahasiswa_id } = req.query;
  
  const query = 'CALL sp_search_proposals(?, ?, ?);';
  conn.query(query, [keyword || null, status_id || null, mahasiswa_id || null], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
};

module.exports = { 
  loginAdmin, 
  addDosen, 
  getAllDosenWithStatus, 
  getAllMahasiswaWithStatus, 
  getAllProposal, 
  assignPembimbing,
  getDashboardStatistics,
  removePembimbing,
  searchProposals
};
