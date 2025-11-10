const express = require('express');
const app = express();
const errorHandler = require('./middleware/errorHandler');
const proposalRoutes = require('./routes/proposal');

app.use(express.json());

// Routes
app.use('/api/mahasiswa', require('./routes/mahasiswa'));
app.use('/api/dosen', require('./routes/dosen'));
app.use('/api/proposal', require('./routes/proposal'));
app.use('/api/pembimbing', require('./routes/pembimbing'));

// Error handler middleware 
app.use(errorHandler);

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
