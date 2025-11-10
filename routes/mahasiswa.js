const express = require('express');
const router = express.Router();
const { registerMahasiswa, loginMahasiswa } = require('../controllers/mahasiswaController');

router.post('/register', registerMahasiswa);
router.post('/login', loginMahasiswa);

module.exports = router;
