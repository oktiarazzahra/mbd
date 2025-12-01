const express = require('express');
const router = express.Router();
const { loginDosen } = require('../controllers/dosenController');

router.post('/login', loginDosen);

module.exports = router;
