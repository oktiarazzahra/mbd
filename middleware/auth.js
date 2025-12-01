const jwt = require('jsonwebtoken');

// Secret key untuk JWT (production: simpan di .env)
const JWT_SECRET = 'your-secret-key-change-this-in-production';

// Middleware untuk verifikasi token mahasiswa
const verifyMahasiswa = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ message: 'Token tidak ditemukan. Silakan login.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Cek apakah role mahasiswa
    if (decoded.role !== 'mahasiswa') {
      return res.status(403).json({ message: 'Akses ditolak. Hanya untuk mahasiswa.' });
    }

    // Simpan data user ke request untuk dipakai di controller
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token tidak valid atau expired.' });
  }
};

// Middleware untuk verifikasi token dosen
const verifyDosen = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token tidak ditemukan. Silakan login.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    if (decoded.role !== 'dosen') {
      return res.status(403).json({ message: 'Akses ditolak. Hanya untuk dosen.' });
    }

    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token tidak valid atau expired.' });
  }
};

// Middleware untuk verifikasi token admin
const verifyAdmin = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token tidak ditemukan. Silakan login.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    if (decoded.role !== 'admin') {
      return res.status(403).json({ message: 'Akses ditolak. Hanya untuk admin.' });
    }

    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token tidak valid atau expired.' });
  }
};

module.exports = { verifyMahasiswa, verifyDosen, verifyAdmin, JWT_SECRET };
