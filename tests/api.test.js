const request = require('supertest');
const app = require('../app');

// Variables to store tokens and IDs
let mahasiswaToken, dosenToken, adminToken;
let mahasiswaId, dosenId, proposalId;
let testNIM, testNIP, testEmail, testDosenEmail;

// Generate unique test data using timestamp
const timestamp = Date.now();
testNIM = `TEST${timestamp}`;
testNIP = `NIP${timestamp}`;
testEmail = `test${timestamp}@test.com`;
testDosenEmail = `dosen${timestamp}@test.com`;

describe('API Tests - MBD System', () => {
  
  // ==================== Authentication Tests ====================
  describe('1. Authentication', () => {
    
    test('POST /api/mahasiswa/register - Register new mahasiswa', async () => {
      const res = await request(app)
        .post('/api/mahasiswa/register')
        .send({
          nim: testNIM,
          nama: `Test Mahasiswa ${timestamp}`,
          email: testEmail,
          password: 'testpass123',
          prodi: 'Teknik Informatika',
          angkatan: 2024
        });
      
      expect(res.statusCode).toBe(201);
      if (res.body.mahasiswa_id) {
        mahasiswaId = res.body.mahasiswa_id;
      }
    });

    test('POST /api/mahasiswa/login - Login mahasiswa', async () => {
      const res = await request(app)
        .post('/api/mahasiswa/login')
        .send({
          email: testEmail,
          password: 'testpass123'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
      mahasiswaToken = res.body.token;
    });

    test('POST /api/admin/login - Login admin', async () => {
      const res = await request(app)
        .post('/api/admin/login')
        .send({
          username: 'admin',
          password: 'admin123'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
      adminToken = res.body.token;
    });
  });

  // ==================== Admin Operations ====================
  describe('2. Admin Operations', () => {
    
    test('POST /api/admin/dosen - Admin creates new dosen', async () => {
      const res = await request(app)
        .post('/api/admin/dosen')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          nip: testNIP,
          nama: `Test Dosen ${timestamp}`,
          email: testDosenEmail,
          password: 'dosenpass123',
          bidang_keahlian: 'Database Systems'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('dosen_id');
      dosenId = res.body.dosen_id;
    });

    test('POST /api/dosen/login - Login newly created dosen', async () => {
      const res = await request(app)
        .post('/api/dosen/login')
        .send({
          email: testDosenEmail,
          password: 'dosenpass123'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
      dosenToken = res.body.token;
    });

    test('GET /api/admin/dosen - Get all dosen with status', async () => {
      const res = await request(app)
        .get('/api/admin/dosen')
        .set('Authorization', `Bearer ${adminToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    test('POST /api/admin/assign-pembimbing - Assign pembimbing', async () => {
      // First submit a proposal for pembimbing testing
      const proposalRes = await request(app)
        .post('/api/proposal')
        .set('Authorization', `Bearer ${mahasiswaToken}`)
        .send({
          judul: `Proposal for Pembimbing ${timestamp}`,
          deskripsi: 'Test proposal for assign pembimbing'
        });
      
      proposalId = proposalRes.body.proposal_id;

      const res = await request(app)
        .post('/api/admin/assign-pembimbing')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          proposal_id: proposalId,
          dosen_id: dosenId
        });
      
      expect(res.statusCode).toBe(200);
    });

    test('GET /api/admin/proposal - Get all proposals', async () => {
      const res = await request(app)
        .get('/api/admin/proposal')
        .set('Authorization', `Bearer ${adminToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    test('GET /api/admin/mahasiswa - Get all mahasiswa', async () => {
      const res = await request(app)
        .get('/api/admin/mahasiswa')
        .set('Authorization', `Bearer ${adminToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    test('DELETE /api/admin/remove-pembimbing - Remove pembimbing', async () => {
      const res = await request(app)
        .delete('/api/admin/remove-pembimbing')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ 
          proposal_id: proposalId,
          dosen_id: dosenId 
        });
      
      expect(res.statusCode).toBe(200);
    });
  });

  // ==================== Mahasiswa Operations ====================
  describe('3. Mahasiswa Operations', () => {
    
    test('GET /api/mahasiswa/proposals - Get mahasiswa proposals', async () => {
      const res = await request(app)
        .get('/api/mahasiswa/proposals')
        .set('Authorization', `Bearer ${mahasiswaToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    test('GET /api/mahasiswa/profile - Get mahasiswa profile', async () => {
      const res = await request(app)
        .get('/api/mahasiswa/profile')
        .set('Authorization', `Bearer ${mahasiswaToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('email');
    });

    test('PUT /api/mahasiswa/profile - Update mahasiswa profile', async () => {
      const res = await request(app)
        .put('/api/mahasiswa/profile')
        .set('Authorization', `Bearer ${mahasiswaToken}`)
        .send({
          nama: `Updated Mahasiswa ${timestamp}`,
          prodi: 'Sistem Informasi'
        });
      
      expect(res.statusCode).toBe(200);
    });
  });

  // ==================== Proposal Operations ====================
  describe('4. Proposal Operations', () => {
    
    test('POST /api/proposal - Submit new proposal', async () => {
      const res = await request(app)
        .post('/api/proposal')
        .set('Authorization', `Bearer ${mahasiswaToken}`)
        .send({
          judul: `New Test Proposal ${timestamp}`,
          deskripsi: 'New test proposal description'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('proposal_id');
      proposalId = res.body.proposal_id;
    });

    test('GET /api/proposal/:id - Get proposal detail', async () => {
      const res = await request(app)
        .get(`/api/proposal/${proposalId}`)
        .set('Authorization', `Bearer ${mahasiswaToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('judul');
    });

    test('PUT /api/proposal/:id - Edit proposal', async () => {
      const res = await request(app)
        .put(`/api/proposal/${proposalId}`)
        .set('Authorization', `Bearer ${mahasiswaToken}`)
        .send({
          judul: `Updated Proposal ${timestamp}`,
          deskripsi: 'Updated description'
        });
      
      expect(res.statusCode).toBe(200);
    });

    test('DELETE /api/proposal/:id - Delete proposal', async () => {
      const res = await request(app)
        .delete(`/api/proposal/${proposalId}`)
        .set('Authorization', `Bearer ${mahasiswaToken}`);
      
      expect(res.statusCode).toBe(200);
    });
  });

  // ==================== Dosen Operations ====================
  describe('5. Dosen Operations', () => {
    
    // Create a new dosen for testing
    beforeAll(async () => {
      const newTimestamp = Date.now();
      const newNIP = `NIP${newTimestamp}`;
      const newDosenEmail = `dosen${newTimestamp}@test.com`;
      
      // Admin creates new dosen
      const createRes = await request(app)
        .post('/api/admin/dosen')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          nip: newNIP,
          nama: `Test Dosen ${newTimestamp}`,
          email: newDosenEmail,
          password: 'dosenpass123',
          bidang_keahlian: 'Software Engineering'
        });
      
      dosenId = createRes.body.dosen_id;
      
      // Login as dosen
      const loginRes = await request(app)
        .post('/api/dosen/login')
        .send({
          email: newDosenEmail,
          password: 'dosenpass123'
        });
      
      dosenToken = loginRes.body.token;
    });

    test('GET /api/dosen/statistics - Get dosen statistics', async () => {
      const res = await request(app)
        .get('/api/dosen/statistics')
        .set('Authorization', `Bearer ${dosenToken}`);
      
      expect(res.statusCode).toBe(200);
    });

    test('PUT /api/dosen/profile - Update dosen profile', async () => {
      const res = await request(app)
        .put('/api/dosen/profile')
        .set('Authorization', `Bearer ${dosenToken}`)
        .send({
          nama: `Updated Dosen ${timestamp}`,
          bidang_keahlian: 'Machine Learning'
        });
      
      expect(res.statusCode).toBe(200);
    });
  });

  // ==================== Pembimbing Operations ====================
  describe('6. Pembimbing Operations', () => {
    
    let testProposalId;
    
    // Setup: Create proposal and assign pembimbing
    beforeAll(async () => {
      // Create proposal
      const proposalRes = await request(app)
        .post('/api/proposal')
        .set('Authorization', `Bearer ${mahasiswaToken}`)
        .send({
          judul: `Pembimbing Test Proposal ${timestamp}`,
          deskripsi: 'Test for pembimbing operations'
        });
      
      testProposalId = proposalRes.body.proposal_id;
      
      // Assign pembimbing
      await request(app)
        .post('/api/admin/assign-pembimbing')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          proposal_id: testProposalId,
          dosen_id: dosenId
        });
    });

    test('GET /api/pembimbing/proposals - Get proposals as pembimbing', async () => {
      const res = await request(app)
        .get('/api/pembimbing/proposals')
        .set('Authorization', `Bearer ${dosenToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    test('POST /api/pembimbing/feedback - Give feedback on proposal', async () => {
      const res = await request(app)
        .post('/api/pembimbing/feedback')
        .set('Authorization', `Bearer ${dosenToken}`)
        .send({
          proposal_id: testProposalId,
          feedback: 'Test feedback dari pembimbing',
          status: 'Revisi'
        });
      
      expect(res.statusCode).toBe(200);
    });

    test('GET /api/pembimbing/proposal-history/:id - Get proposal history', async () => {
      const res = await request(app)
        .get(`/api/pembimbing/proposal-history/${testProposalId}`)
        .set('Authorization', `Bearer ${dosenToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  // ==================== Authorization Tests ====================
  describe('7. Authorization Tests', () => {
    
    test('GET /api/admin/dosen without token - Should return 401', async () => {
      const res = await request(app)
        .get('/api/admin/dosen');
      
      expect(res.statusCode).toBe(401);
    });

    test('GET /api/dosen/statistics without token - Should return 401', async () => {
      const res = await request(app)
        .get('/api/dosen/statistics');
      
      expect(res.statusCode).toBe(401);
    });

    test('GET /api/mahasiswa/profile without token - Should return 401', async () => {
      const res = await request(app)
        .get('/api/mahasiswa/profile');
      
      expect(res.statusCode).toBe(401);
    });

    test('POST /api/proposal without token - Should return 401', async () => {
      const res = await request(app)
        .post('/api/proposal')
        .send({
          judul: 'Test',
          deskripsi: 'Test'
        });
      
      expect(res.statusCode).toBe(401);
    });
  });
});
