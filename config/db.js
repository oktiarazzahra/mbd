const mysql = require('mysql2');

const conn = mysql.createConnection({
  port: 3306,
  host: "localhost",
  user: "root",
  password: "",
  database: "mbd",
  connectTimeout: 10000,
  multipleStatements: true
});

conn.connect((err) => {
  if (err) {
    console.log("❌ ERROR Database:", err.message);
    return;
  }
  console.log("✓ Connected to database!");
});

module.exports = conn;
