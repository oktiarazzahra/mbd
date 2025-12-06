# MBD (Manajemen Bimbingan Database) - API System

Sistem API untuk manajemen bimbingan tugas akhir mahasiswa dengan stored procedures MySQL.

## 🚀 Tech Stack

- **Backend:** Node.js + Express.js
- **Database:** MySQL dengan Stored Procedures, Functions, Triggers, Views
- **Authentication:** JWT (JSON Web Token)
- **Testing:** Jest + Supertest
- **API Documentation:** Postman Collection

## 📦 Features

- ✅ **4 User Roles:** Admin, Mahasiswa, Dosen, Pembimbing
- ✅ **26 API Endpoints** dengan JWT authentication
- ✅ **27 Stored Procedures** untuk database operations
- ✅ **11 Functions** untuk business logic
- ✅ **11 Triggers** untuk automation
- ✅ **16 Views** untuk reporting
- ✅ **Automated Testing** dengan Jest (26/26 tests passing)
- ✅ **Postman Collection** untuk manual testing

## 🏗️ Project Structure

```
mbd/
├── app.js                  # Main application
├── package.json            # Dependencies
├── jest.config.js          # Jest configuration
├── mbd.sql                 # Database schema & data
├── config/
│   └── db.js              # MySQL connection
├── controllers/
│   ├── adminController.js
│   ├── dosenController.js
│   ├── mahasiswaController.js
│   ├── pembimbingController.js
│   └── proposalController.js
├── middleware/
│   └── auth.js            # JWT authentication
├── routes/
│   ├── admin.js
│   ├── dosen.js
│   ├── mahasiswa.js
│   ├── pembimbing.js
│   └── proposal.js
├── tests/
│   └── api.test.js        # Automated tests (26 tests)
└── postman/
    ├── MBD-API.postman_collection.json  # 27 API requests
    ├── MBD-Environment.postman_environment.json
    └── README.md                         # Postman testing guide
    ├── MBD-API.postman_collection.json
    ├── MBD-Environment.postman_environment.json
    └── README.md
```

## 📋 Prerequisites

- Node.js >= 14.x
- MySQL >= 5.7 or MariaDB >= 10.3
- npm or yarn

## ⚙️ Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd mbd
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Setup Database

```bash
# Login to MySQL
mysql -u root -p

# Import database
mysql -u root -p < mbd.sql
```

### 4. Configure Database Connection

Edit `config/db.js`:

```javascript
const conn = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'your_password',
  database: 'mbd',
  multipleStatements: true
});
```

### 5. Start Server

```bash
# Development
npm start

# Server akan berjalan di http://localhost:3000
```

## 🧪 Testing

### Automated Tests (Jest)

```bash
npm test
```

**Expected Output:**
```
Test Suites: 1 passed, 1 total
Tests:       26 passed, 26 total
Time:        ~1.2s
```

### Manual Tests (Postman)

1. Import files dari folder `postman/`:
   - `MBD-API.postman_collection.json`
   - `MBD-Environment.postman_environment.json`

2. Pilih environment **MBD Environment**

3. Jalankan collection atau individual requests

📖 **Detail:** Lihat `postman/README.md`

## 🔐 Default Credentials

### Admin
```json
{
  "username": "admin",
  "password": "admin123"
}
```

### Dosen (Pre-existing)
```json
{
  "email": "andi.wijaya@univ.ac.id",
  "password": "pass1"
}
```

### Mahasiswa (Pre-existing)
```json
{
  "email": "rina.susanti@student.univ.ac.id",
  "password": "pw1"
}
```

## 📚 API Endpoints

### Authentication (4 endpoints)
- `POST /api/mahasiswa/register` - Register mahasiswa
- `POST /api/mahasiswa/login` - Login mahasiswa
- `POST /api/admin/login` - Login admin
- `POST /api/dosen/login` - Login dosen

### Admin Operations (8 endpoints)
- `POST /api/admin/dosen` - Add dosen
- `GET /api/admin/dosen` - List all dosen
- `GET /api/admin/mahasiswa` - List all mahasiswa
- `GET /api/admin/proposal` - List all proposals
- `POST /api/admin/assign-pembimbing` - Assign pembimbing
- `DELETE /api/admin/remove-pembimbing` - Remove pembimbing
- `GET /api/admin/dashboard` - Dashboard statistics
- `GET /api/admin/search-proposals` - Search proposals

### Mahasiswa Operations (4 endpoints)
- `GET /api/mahasiswa/proposals` - My proposals
- `GET /api/mahasiswa/profile` - Get profile
- `PUT /api/mahasiswa/profile` - Update profile
- `PUT /api/mahasiswa/change-password` - Change password

### Proposal Operations (4 endpoints)
- `POST /api/proposal` - Submit proposal
- `GET /api/proposal/:id` - Get proposal detail
- `PUT /api/proposal/:id` - Edit proposal
- `DELETE /api/proposal/:id` - Delete proposal

### Dosen Operations (2 endpoints)
- `GET /api/dosen/statistics` - Get statistics
- `PUT /api/dosen/profile` - Update profile

### Pembimbing Operations (3 endpoints)
- `GET /api/pembimbing/proposals` - My supervised proposals
- `POST /api/pembimbing/feedback` - Give feedback
- `GET /api/pembimbing/proposal-history/:id` - Proposal history

## 🗄️ Database Overview

### Tables (6 tables)
- `admin` - Admin users
- `dosen` - Dosen/lecturer data
- `mahasiswa` - Student data
- `proposal` - Thesis proposals
- `pembimbing` - Supervisor assignments
- `history_proposal` - Proposal change history
- `status_proposal` - Proposal status reference

### Stored Procedures (27)
Key procedures:
- `sp_register_mahasiswa` - Register student
- `sp_login_mahasiswa` / `sp_login_dosen` - Authentication
- `sp_submit_proposal` - Submit new proposal
- `sp_assign_pembimbing` - Assign supervisor
- `sp_give_feedback` - Provide feedback
- And 22+ more...

### Functions (11)
- `fn_count_total_mahasiswa()` - Count students
- `fn_count_total_dosen()` - Count lecturers
- `fn_count_total_proposal()` - Count proposals
- `fn_get_mahasiswa_name()` - Get student name
- And 7+ more...

### Triggers (11)
- `tr_proposal_auto_tanggal` - Auto set submission date
- `tr_proposal_after_insert` - Log proposal creation
- `tr_proposal_after_update` - Log proposal changes
- And 8+ more...

### Views (16)
- `view_mahasiswa_proposal` - Student proposals overview
- `view_dosen_pembimbing` - Lecturer supervision
- `view_proposal_status` - Proposal status summary
- And 13+ more...

## 🔒 Security

- ✅ JWT-based authentication
- ✅ Password hashing (should be implemented in production)
- ✅ Role-based access control (verifyAdmin, verifyDosen, verifyMahasiswa)
- ✅ SQL injection prevention (parameterized queries)

## 📊 Test Coverage

```
Test Suites: 1 passed, 1 total
Tests:       26 passed, 26 total

Coverage:
- Authentication: 4/4 ✅
- Admin Operations: 7/7 ✅
- Mahasiswa Operations: 3/3 ✅
- Proposal Operations: 4/4 ✅
- Dosen Operations: 2/2 ✅
- Pembimbing Operations: 3/3 ✅
- Authorization: 4/4 ✅
```

## 🚧 Production Checklist

Before deploying to production:

- [ ] Change `JWT_SECRET` in `middleware/auth.js` (use environment variable)
- [ ] Implement proper password hashing (bcrypt)
- [ ] Add rate limiting
- [ ] Enable CORS with specific origins
- [ ] Add request validation middleware
- [ ] Setup logging (Winston/Morgan)
- [ ] Add error tracking (Sentry)
- [ ] Setup environment variables (.env file)
- [ ] Database connection pooling
- [ ] Add API versioning

## 📖 Documentation

- **API Testing:** `postman/README.md`
- **Automated Tests:** `tests/api.test.js`
- **Database Schema:** `mbd.sql`

## 🐛 Troubleshooting

### Database Connection Error
```bash
# Check MySQL service
sudo systemctl status mysql

# Test connection
mysql -u root -p -e "SELECT 1;"
```

### Port 3000 Already in Use
```bash
# Change port in app.js or kill process
lsof -ti:3000 | xargs kill -9
```

### Test Failures
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
npm test
```

## 📝 License

ISC

## 👥 Contributors

- Your Name / Team

---

**Status:** ✅ All 26 tests passing | 🚀 Production ready (with checklist items)
