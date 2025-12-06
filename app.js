const express = require('express');
const app = express();

app.use(express.json());

// Routes
app.use('/api/mahasiswa', require('./routes/mahasiswa'));
app.use('/api/dosen', require('./routes/dosen'));
app.use('/api/proposal', require('./routes/proposal'));
app.use('/api/pembimbing', require('./routes/pembimbing'));
app.use('/api/admin', require('./routes/admin'));


// Only start server if this file is run directly (not imported for testing)
if (require.main === module) {
  const PORT = 3000;
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
