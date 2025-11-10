const express = require('express');
const router = express.Router();
const { registerDosen, loginDosen } = require('../controllers/dosenController');

router.post('/register', registerDosen);
router.post('/login', loginDosen);

module.exports = router;
