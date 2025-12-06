-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 06 Des 2025 pada 01.29
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mbd`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_view_all_dosen` ()   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_admin_all_dosen
    ORDER BY nama ASC;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_view_all_mahasiswa` ()   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_admin_all_mahasiswa
    ORDER BY angkatan DESC, nama ASC;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_view_all_proposal` ()   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_admin_all_proposal
    ORDER BY tanggal_ajuan DESC;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_assign_pembimbing` (IN `p_proposal_id` INT, IN `p_dosen_id` INT, IN `p_jenis` VARCHAR(1), OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_prop INT DEFAULT 0;
   DECLARE v_dosen INT DEFAULT 0;
   DECLARE v_exist INT DEFAULT 0;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_message = 'Error: terjadi kesalahan saat assign pembimbing';
   END;

   START TRANSACTION;

   -- cek proposal ada
   SELECT COUNT(*) INTO v_prop
   FROM proposal
   WHERE proposal_id = p_proposal_id;

   -- cek dosen ada
   SELECT COUNT(*) INTO v_dosen
   FROM dosen
   WHERE dosen_id = p_dosen_id;

   IF v_prop = 0 THEN
       ROLLBACK;
       SET p_message = 'Error: proposal tidak ditemukan';
   ELSEIF v_dosen = 0 THEN
       ROLLBACK;
       SET p_message = 'Error: dosen tidak ditemukan';
   ELSE
       -- cek apakah jenis pembimbing ini sudah ada
       SELECT COUNT(*) INTO v_exist
       FROM pembimbing
       WHERE proposal_id = p_proposal_id
         AND jenis = p_jenis;

       IF v_exist > 0 THEN
           ROLLBACK;
           SET p_message = 'Error: pembimbing dengan jenis ini sudah ada';
       ELSE
           INSERT INTO pembimbing(proposal_id, dosen_id, jenis, status, tanggal_mulai)
           VALUES(p_proposal_id, p_dosen_id, p_jenis, 'aktif', CURDATE());

           COMMIT;
           SET p_message = 'Pembimbing berhasil diberikan';
       END IF;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_proposal` (IN `p_proposal_id` INT, IN `p_mahasiswa_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count INT;
   DECLARE v_status_id INT;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_message = 'Error: terjadi kesalahan saat menghapus proposal';
   END;

   START TRANSACTION;

   SELECT COUNT(*), status_id
   INTO v_count, v_status_id
   FROM proposal
   WHERE proposal_id = p_proposal_id
     AND mahasiswa_id = p_mahasiswa_id;

   IF v_count = 0 THEN
       ROLLBACK;
       SET p_message = 'Error: proposal tidak ditemukan atau bukan milik mahasiswa';
   ELSEIF v_status_id NOT IN (1, 4, 5) THEN
       ROLLBACK;
       SET p_message = 'Error: hanya proposal dengan status Diajukan, Ditolak, atau Perlu Revisi yang dapat dihapus';
   ELSE
       DELETE FROM pembimbing
       WHERE proposal_id = p_proposal_id;

       DELETE FROM history_proposal
       WHERE proposal_id = p_proposal_id;

       DELETE FROM proposal
       WHERE proposal_id = p_proposal_id;

       COMMIT;
       SET p_message = 'Proposal berhasil dihapus';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_dosen_view_proposal_detail` (IN `p_dosen_id` INT, IN `p_proposal_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_dosen_proposal_detail
    WHERE dosen_id = p_dosen_id
      AND proposal_id = p_proposal_id;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_edit_proposal` (IN `p_proposal_id` INT, IN `p_mahasiswa_id` INT, IN `p_judul` TEXT, IN `p_abstrak` TEXT, IN `p_catatan` TEXT, OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_count INT;
    DECLARE v_status_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Terjadi kesalahan saat update proposal';
    END;

    START TRANSACTION;

    SELECT COUNT(*), status_id INTO v_count, v_status_id
    FROM proposal
    WHERE proposal_id = p_proposal_id
      AND mahasiswa_id = p_mahasiswa_id;

    IF v_count = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: proposal tidak ditemukan atau bukan milik Anda!';
    ELSEIF v_status_id <> 5 THEN
        ROLLBACK;
        SET p_message = 'Error: proposal hanya dapat diedit jika status Perlu Revisi';
    ELSE
        UPDATE proposal
        SET judul = p_judul,
            abstrak = p_abstrak,
            catatan = p_catatan,
            updated_at = NOW()
        WHERE proposal_id = p_proposal_id;

        INSERT INTO history_proposal(proposal_id, status_id, catatan, created_at, updated_at)
        VALUES(p_proposal_id, v_status_id, 'Proposal diupdate oleh mahasiswa', NOW(), NOW());

        COMMIT;
        SET p_message = 'Proposal berhasil diupdate!';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_proposal_bimbingan` (IN `p_dosen_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_proposal_bimbingan
    WHERE dosen_id = p_dosen_id
    ORDER BY tanggal_ajuan DESC;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_proposal_detail` (IN `p_proposal_id` INT)   BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  SELECT
    p.proposal_id,
    p.judul,
    p.abstrak,
    p.catatan,
    p.tanggal_ajuan,
    sp.nama_status,
    m.nim,
    m.nama AS nama_mahasiswa,
    GROUP_CONCAT(DISTINCT CONCAT(d.nama, ' (', pb.jenis, ')') SEPARATOR ', ') AS pembimbing,
    h.catatan AS feedback,
    h.created_at AS tanggal_feedback
  FROM proposal p
  LEFT JOIN status_proposal sp ON p.status_id = sp.status_id
  LEFT JOIN mahasiswa m ON p.mahasiswa_id = m.mahasiswa_id
  LEFT JOIN pembimbing pb ON p.proposal_id = pb.proposal_id
  LEFT JOIN dosen d ON pb.dosen_id = d.dosen_id
  LEFT JOIN history_proposal h ON p.proposal_id = h.proposal_id
  WHERE p.proposal_id = p_proposal_id
  GROUP BY p.proposal_id, p.judul, p.abstrak, p.catatan, p.tanggal_ajuan,
           sp.nama_status, m.nim, m.nama, h.catatan, h.created_at;

  COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_give_feedback` (IN `p_proposal_id` INT, IN `p_dosen_id` INT, IN `p_feedback` TEXT, IN `p_new_status_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_is_pembimbing INT;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_message = 'Error: terjadi kesalahan saat memberikan feedback';
   END;

   START TRANSACTION;

   SELECT COUNT(*)
   INTO v_is_pembimbing
   FROM pembimbing
   WHERE proposal_id = p_proposal_id
     AND dosen_id = p_dosen_id
     AND status = 'aktif';

   IF v_is_pembimbing = 0 THEN
       ROLLBACK;
       SET p_message = 'Error: dosen bukan pembimbing dari proposal ini';
   ELSE
       UPDATE proposal
       SET status_id = p_new_status_id,
           catatan = p_feedback,
           updated_at = NOW()
       WHERE proposal_id = p_proposal_id;

       INSERT INTO history_proposal(proposal_id, status_id, catatan, created_at, updated_at)
       VALUES(p_proposal_id, p_new_status_id, CONCAT('Feedback dari dosen: ', p_feedback), NOW(), NOW());

       COMMIT;
       SET p_message = 'Feedback berhasil diberikan';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_admin` (IN `p_username` VARCHAR(50), IN `p_password` VARCHAR(255), OUT `p_admin_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_id INT DEFAULT 0;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_admin_id = 0;
       SET p_message = 'Error: terjadi masalah saat login admin';
   END;

   START TRANSACTION;

   SELECT admin_id
   INTO v_id
   FROM admin
   WHERE username = p_username
     AND password = p_password
   LIMIT 1;

   IF v_id IS NULL OR v_id = 0 THEN
       ROLLBACK;
       SET p_admin_id = 0;
       SET p_message = 'Login gagal: username atau password salah';
   ELSE
       COMMIT;
       SET p_admin_id = v_id;
       SET p_message = 'Login admin berhasil';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_dosen` (IN `p_email` VARCHAR(100), IN `p_password` VARCHAR(255), OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count INT DEFAULT 0;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_message = 'Error: terjadi masalah login dosen';
   END;

   START TRANSACTION;

   SELECT COUNT(*) INTO v_count
   FROM dosen
   WHERE email = p_email AND password = p_password;

   IF v_count = 1 THEN
       COMMIT;
       SET p_message = 'Login dosen berhasil';
   ELSE
       ROLLBACK;
       SET p_message = 'Login gagal: email atau password salah';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_mahasiswa` (IN `p_email` VARCHAR(100), IN `p_password` VARCHAR(255), OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count INT DEFAULT 0;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_message = 'Error: terjadi masalah saat login';
   END;

   START TRANSACTION;

   SELECT COUNT(*) INTO v_count
   FROM mahasiswa
   WHERE email = p_email AND password = p_password;

   IF v_count = 1 THEN
       COMMIT;
       SET p_message = 'Login berhasil';
   ELSE
       ROLLBACK;
       SET p_message = 'Login gagal: email atau password salah';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_register_dosen` (IN `p_nip` VARCHAR(20), IN `p_nama` VARCHAR(100), IN `p_email` VARCHAR(100), IN `p_password` VARCHAR(255), IN `p_bidang_keahlian` VARCHAR(50), OUT `p_dosen_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count_nip INT DEFAULT 0;
   DECLARE v_count_email INT DEFAULT 0;
   DECLARE v_id INT;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_dosen_id = 0;
       SET p_message = 'Gagal tambah dosen';
   END;

   START TRANSACTION;

   SELECT COUNT(*) INTO v_count_nip FROM dosen WHERE nip = p_nip;
   SELECT COUNT(*) INTO v_count_email FROM dosen WHERE email = p_email;

   IF v_count_nip > 0 THEN
       ROLLBACK;
       SET p_dosen_id = 0;
       SET p_message = 'NIP sudah terdaftar';
   ELSEIF v_count_email > 0 THEN
       ROLLBACK;
       SET p_dosen_id = 0;
       SET p_message = 'Email sudah terpakai';
   ELSE
       INSERT INTO dosen(nip, nama, email, password, bidang_keahlian, created_at)
       VALUES(p_nip, p_nama, p_email, p_password, p_bidang_keahlian, NOW());
       COMMIT;
       SELECT dosen_id INTO v_id FROM dosen WHERE email = p_email LIMIT 1;
       SET p_dosen_id = v_id;
       SET p_message = 'Dosen berhasil ditambahkan';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_register_mahasiswa` (IN `p_nim` VARCHAR(20), IN `p_nama` VARCHAR(100), IN `p_email` VARCHAR(100), IN `p_password` VARCHAR(255), IN `p_prodi` VARCHAR(50), IN `p_angkatan` YEAR, OUT `p_mahasiswa_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count_nim INT DEFAULT 0;
   DECLARE v_count_email INT DEFAULT 0;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_mahasiswa_id = 0;
       SET p_message = 'Gagal registrasi mahasiswa';
   END;

   START TRANSACTION;

   SELECT COUNT(*) INTO v_count_nim FROM mahasiswa WHERE nim = p_nim;
   SELECT COUNT(*) INTO v_count_email FROM mahasiswa WHERE email = p_email;

   IF v_count_nim > 0 THEN
       ROLLBACK;
       SET p_mahasiswa_id = 0;
       SET p_message = 'NIM sudah terdaftar';
   ELSEIF v_count_email > 0 THEN
       ROLLBACK;
       SET p_mahasiswa_id = 0;
       SET p_message = 'Email sudah terpakai';
   ELSE
       INSERT INTO mahasiswa(nim, nama, email, password, prodi, angkatan)
       VALUES(p_nim, p_nama, p_email, p_password, p_prodi, p_angkatan);

       SET p_mahasiswa_id = LAST_INSERT_ID();
       COMMIT;
       SET p_message = 'Registrasi berhasil';
       SELECT p_mahasiswa_id AS id, p_message AS message;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_submit_proposal` (IN `p_mahasiswa_id` INT, IN `p_judul` TEXT, IN `p_abstrak` TEXT, IN `p_catatan` TEXT, OUT `p_proposal_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
   DECLARE v_count INT;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_proposal_id = 0;
       SET p_message = 'Error: Terjadi kegagalan saat submit proposal';
   END;

   START TRANSACTION;

   SELECT COUNT(*) INTO v_count FROM mahasiswa WHERE mahasiswa_id = p_mahasiswa_id;

   IF v_count = 0 THEN
       ROLLBACK;
       SET p_proposal_id = 0;
       SET p_message = 'Error: mahasiswa tidak ditemukan';

   ELSE
       INSERT INTO proposal
         (mahasiswa_id, status_id, judul, abstrak, catatan, tanggal_ajuan,
created_at, updated_at)
       VALUES
         (p_mahasiswa_id, 1, p_judul, p_abstrak, p_catatan, NOW(), NOW(), NOW());

       SET p_proposal_id = LAST_INSERT_ID();

       INSERT INTO history_proposal
         (proposal_id, status_id, catatan, created_at, updated_at)
       VALUES
         (p_proposal_id, 1, 'Proposal diajukan', NOW(), NOW());

       COMMIT;
       SET p_message = 'Proposal berhasil diajukan';
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_proposal_status_feedback` (IN `p_mahasiswa_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    SELECT *
    FROM vw_proposal_status_feedback
    WHERE mahasiswa_id = p_mahasiswa_id
    ORDER BY tanggal_feedback DESC;

    COMMIT;
END$$

--
-- Fungsi
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_calculate_bimbingan_duration` (`p_proposal_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE start_date DATE;
   DECLARE duration_days INT DEFAULT 0;
   SELECT tanggal_mulai
     INTO start_date
     FROM pembimbing
    WHERE proposal_id = p_proposal_id
    ORDER BY tanggal_mulai
    LIMIT 1;
   IF start_date IS NOT NULL THEN
       SET duration_days = DATEDIFF(CURDATE(), start_date);
   END IF;
   RETURN duration_days;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_count_proposal_mahasiswa_history` (`p_mahasiswa_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE total_history INT DEFAULT 0;
   SELECT COUNT(h.history_id)
     INTO total_history
     FROM history_proposal h
     JOIN proposal p ON h.proposal_id = p.proposal_id
    WHERE p.mahasiswa_id = p_mahasiswa_id;
   RETURN total_history;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_get_current_status` (`p_proposal_id` INT) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
   DECLARE current_status VARCHAR(50);
   SELECT sp.nama_status
     INTO current_status
     FROM proposal p
     JOIN status_proposal sp ON p.status_id = sp.status_id
    WHERE p.proposal_id = p_proposal_id;
   RETURN IFNULL(current_status,'Status tidak ditemukan');
END$$

-- ============================================
-- ADDITIONAL FUNCTIONS (Database Improvements)
-- ============================================

-- Function: Hitung proposal aktif mahasiswa
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_count_active_proposals`(`p_mahasiswa_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total INT DEFAULT 0;
    
    SELECT COUNT(*) INTO total
    FROM proposal
    WHERE mahasiswa_id = p_mahasiswa_id
      AND status_id NOT IN (4, 6);
    
    RETURN total;
END$$

-- Function: Hitung total bimbingan dosen
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_count_dosen_bimbingan`(`p_dosen_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total INT DEFAULT 0;
    
    SELECT COUNT(*) INTO total
    FROM pembimbing
    WHERE dosen_id = p_dosen_id
      AND status = 'aktif';
    
    RETURN total;
END$$

-- Function: Dapatkan nama pembimbing dalam format string
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_get_pembimbing_names`(`p_proposal_id` INT) RETURNS VARCHAR(500) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE names VARCHAR(500);
    
    SELECT GROUP_CONCAT(CONCAT(d.nama, ' (', pb.jenis, ')') SEPARATOR ', ')
    INTO names
    FROM pembimbing pb
    JOIN dosen d ON pb.dosen_id = d.dosen_id
    WHERE pb.proposal_id = p_proposal_id
      AND pb.status = 'aktif';
    
    RETURN IFNULL(names, 'Belum ada pembimbing');
END$$

-- Function: Validasi format email
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_validate_email`(`p_email` VARCHAR(100)) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    IF p_email LIKE '%@%.%' AND p_email NOT LIKE '% %' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

-- Function: Umur proposal dalam hari
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_get_proposal_age_days`(`p_proposal_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE age_days INT DEFAULT 0;
    DECLARE submit_date DATETIME;
    
    SELECT tanggal_ajuan INTO submit_date
    FROM proposal
    WHERE proposal_id = p_proposal_id;
    
    IF submit_date IS NOT NULL THEN
        SET age_days = DATEDIFF(CURDATE(), DATE(submit_date));
    END IF;
    
    RETURN age_days;
END$$

-- Function: Cek kelengkapan proposal
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_check_proposal_completeness`(`p_proposal_id` INT) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE pembimbing_count INT;
    DECLARE status VARCHAR(50);
    
    SELECT COUNT(*) INTO pembimbing_count
    FROM pembimbing
    WHERE proposal_id = p_proposal_id
      AND status = 'aktif';
    
    IF pembimbing_count = 0 THEN
        SET status = 'Belum ada pembimbing';
    ELSEIF pembimbing_count = 1 THEN
        SET status = 'Pembimbing tidak lengkap';
    ELSE
        SET status = 'Lengkap';
    END IF;
    
    RETURN status;
END$$

-- Function: Beban kerja dosen
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_get_dosen_workload`(`p_dosen_id` INT) RETURNS VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE bimbingan_count INT;
    DECLARE workload VARCHAR(50);
    
    SELECT COUNT(*) INTO bimbingan_count
    FROM pembimbing
    WHERE dosen_id = p_dosen_id
      AND status = 'aktif';
    
    IF bimbingan_count = 0 THEN
        SET workload = 'Tidak ada bimbingan';
    ELSEIF bimbingan_count <= 3 THEN
        SET workload = 'Ringan';
    ELSEIF bimbingan_count <= 6 THEN
        SET workload = 'Sedang';
    ELSE
        SET workload = 'Berat';
    END IF;
    
    RETURN workload;
END$$

-- Function: Hitung total history proposal mahasiswa
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_count_proposal_history_by_mahasiswa`(`p_mahasiswa_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total INT DEFAULT 0;
    
    SELECT COUNT(DISTINCT p.proposal_id) INTO total
    FROM proposal p
    WHERE p.mahasiswa_id = p_mahasiswa_id;
    
    RETURN total;
END$$

-- ============================================
-- ADDITIONAL STORED PROCEDURES (Database Improvements)
-- ============================================

-- SP: Get semua proposal mahasiswa
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_mahasiswa_proposals` (IN `p_mahasiswa_id` INT)   BEGIN
    SELECT 
        p.proposal_id,
        p.judul,
        p.abstrak,
        sp.nama_status,
        p.tanggal_ajuan,
        p.updated_at,
        fn_get_pembimbing_names(p.proposal_id) AS pembimbing,
        fn_get_proposal_age_days(p.proposal_id) AS umur_hari,
        fn_check_proposal_completeness(p.proposal_id) AS kelengkapan
    FROM proposal p
    JOIN status_proposal sp ON p.status_id = sp.status_id
    WHERE p.mahasiswa_id = p_mahasiswa_id
    ORDER BY p.tanggal_ajuan DESC;
END$$

-- SP: Update profil mahasiswa
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_mahasiswa_profile` (IN `p_mahasiswa_id` INT, IN `p_nama` VARCHAR(100), IN `p_prodi` VARCHAR(50), OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Gagal update profil mahasiswa';
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_count
    FROM mahasiswa
    WHERE mahasiswa_id = p_mahasiswa_id;
    
    IF v_count = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: mahasiswa tidak ditemukan';
    ELSE
        UPDATE mahasiswa
        SET nama = p_nama,
            prodi = p_prodi
        WHERE mahasiswa_id = p_mahasiswa_id;
        
        COMMIT;
        SET p_message = 'Profil mahasiswa berhasil diupdate';
    END IF;
END$$

-- SP: Update profil dosen
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_dosen_profile` (IN `p_dosen_id` INT, IN `p_nama` VARCHAR(100), IN `p_bidang_keahlian` VARCHAR(50), OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Gagal update profil dosen';
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_count
    FROM dosen
    WHERE dosen_id = p_dosen_id;
    
    IF v_count = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: dosen tidak ditemukan';
    ELSE
        UPDATE dosen
        SET nama = p_nama,
            bidang_keahlian = p_bidang_keahlian
        WHERE dosen_id = p_dosen_id;
        
        COMMIT;
        SET p_message = 'Profil dosen berhasil diupdate';
    END IF;
END$$

-- SP: Change password mahasiswa
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_change_password_mahasiswa` (IN `p_mahasiswa_id` INT, IN `p_old_password` VARCHAR(255), IN `p_new_password` VARCHAR(255), OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_current_password VARCHAR(255);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Gagal mengubah password';
    END;
    
    START TRANSACTION;
    
    SELECT password INTO v_current_password
    FROM mahasiswa
    WHERE mahasiswa_id = p_mahasiswa_id;
    
    IF v_current_password IS NULL THEN
        ROLLBACK;
        SET p_message = 'Error: mahasiswa tidak ditemukan';
    ELSEIF v_current_password != p_old_password THEN
        ROLLBACK;
        SET p_message = 'Error: Password lama tidak sesuai';
    ELSEIF LENGTH(p_new_password) < 6 THEN
        ROLLBACK;
        SET p_message = 'Error: Password baru minimal 6 karakter';
    ELSE
        UPDATE mahasiswa
        SET password = p_new_password
        WHERE mahasiswa_id = p_mahasiswa_id;
        
        COMMIT;
        SET p_message = 'Password berhasil diubah';
    END IF;
END$$

-- SP: Change password dosen
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_change_password_dosen` (IN `p_dosen_id` INT, IN `p_old_password` VARCHAR(255), IN `p_new_password` VARCHAR(255), OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_current_password VARCHAR(255);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Gagal mengubah password';
    END;
    
    START TRANSACTION;
    
    SELECT password INTO v_current_password
    FROM dosen
    WHERE dosen_id = p_dosen_id;
    
    IF v_current_password IS NULL THEN
        ROLLBACK;
        SET p_message = 'Error: dosen tidak ditemukan';
    ELSEIF v_current_password != p_old_password THEN
        ROLLBACK;
        SET p_message = 'Error: Password lama tidak sesuai';
    ELSEIF LENGTH(p_new_password) < 6 THEN
        ROLLBACK;
        SET p_message = 'Error: Password baru minimal 6 karakter';
    ELSE
        UPDATE dosen
        SET password = p_new_password
        WHERE dosen_id = p_dosen_id;
        
        COMMIT;
        SET p_message = 'Password berhasil diubah';
    END IF;
END$$

-- SP: Dashboard statistics
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_dashboard_statistics` ()   BEGIN
    SELECT 
        (SELECT COUNT(*) FROM mahasiswa) AS total_mahasiswa,
        (SELECT COUNT(*) FROM dosen) AS total_dosen,
        (SELECT COUNT(*) FROM proposal) AS total_proposal,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 1) AS proposal_diajukan,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 2) AS proposal_review,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 3) AS proposal_disetujui,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 4) AS proposal_ditolak,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 5) AS proposal_revisi,
        (SELECT COUNT(*) FROM proposal WHERE status_id = 6) AS proposal_selesai,
        (SELECT COUNT(*) FROM pembimbing WHERE status = 'aktif') AS pembimbing_aktif;
END$$

-- SP: Remove pembimbing dari proposal
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_remove_pembimbing` (IN `p_proposal_id` INT, IN `p_dosen_id` INT, OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE v_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Error: Gagal menghapus pembimbing';
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_count
    FROM pembimbing
    WHERE proposal_id = p_proposal_id
      AND dosen_id = p_dosen_id;
    
    IF v_count = 0 THEN
        ROLLBACK;
        SET p_message = 'Error: pembimbing tidak ditemukan';
    ELSE
        DELETE FROM pembimbing
        WHERE proposal_id = p_proposal_id
          AND dosen_id = p_dosen_id;
        
        COMMIT;
        SET p_message = 'Pembimbing berhasil dihapus';
    END IF;
END$$

-- SP: Get riwayat lengkap proposal
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_proposal_history` (IN `p_proposal_id` INT)   BEGIN
    SELECT 
        h.history_id,
        h.proposal_id,
        sp.nama_status,
        h.catatan,
        h.created_at AS tanggal,
        DATEDIFF(NOW(), h.created_at) AS hari_lalu
    FROM history_proposal h
    JOIN status_proposal sp ON h.status_id = sp.status_id
    WHERE h.proposal_id = p_proposal_id
    ORDER BY h.created_at DESC;
END$$

-- SP: Search proposals dengan filter
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_proposals` (IN `p_keyword` VARCHAR(255), IN `p_status_id` INT, IN `p_mahasiswa_id` INT)   BEGIN
    SELECT 
        p.proposal_id,
        p.judul,
        m.nim,
        m.nama AS nama_mahasiswa,
        sp.nama_status,
        p.tanggal_ajuan,
        fn_get_pembimbing_names(p.proposal_id) AS pembimbing
    FROM proposal p
    JOIN mahasiswa m ON p.mahasiswa_id = m.mahasiswa_id
    JOIN status_proposal sp ON p.status_id = sp.status_id
    WHERE (p_keyword IS NULL OR p.judul LIKE CONCAT('%', p_keyword, '%'))
      AND (p_status_id IS NULL OR p.status_id = p_status_id)
      AND (p_mahasiswa_id IS NULL OR p.mahasiswa_id = p_mahasiswa_id)
    ORDER BY p.tanggal_ajuan DESC;
END$$

-- SP: Get statistik dosen
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_dosen_statistics` (IN `p_dosen_id` INT)   BEGIN
    SELECT 
        d.dosen_id,
        d.nama,
        d.nip,
        d.bidang_keahlian,
        fn_count_dosen_bimbingan(d.dosen_id) AS total_bimbingan_aktif,
        fn_get_dosen_workload(d.dosen_id) AS beban_kerja,
        (SELECT COUNT(*) FROM pembimbing WHERE dosen_id = d.dosen_id) AS total_bimbingan_keseluruhan,
        (SELECT COUNT(*) FROM pembimbing WHERE dosen_id = d.dosen_id AND status = 'selesai') AS bimbingan_selesai
    FROM dosen d
    WHERE d.dosen_id = p_dosen_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `admin`
--

INSERT INTO `admin` (`admin_id`, `username`, `password`, `nama`, `created_at`) VALUES
(1, 'admin', 'admin123', 'Administrator Sistem', '2025-11-30 03:12:15');

-- --------------------------------------------------------

--
-- Struktur dari tabel `dosen`
--

CREATE TABLE `dosen` (
  `dosen_id` int(11) NOT NULL,
  `nip` varchar(20) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `bidang_keahlian` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `dosen`
--

INSERT INTO `dosen` (`dosen_id`, `nip`, `nama`, `email`, `password`, `bidang_keahlian`, `created_at`) VALUES
(1, 'D001', 'Dr. Andi Wijaya, M.Kom', 'andi.wijaya@univ.ac.id', 'pass1', 'Sistem Informasi', '2025-11-04 03:07:23'),
(2, 'D002', 'Prof. Dr. Siti Rahmah, M.T', 'siti.rahmah@univ.ac.id', 'pass2', 'Basis Data', '2025-11-04 03:07:23'),
(3, 'D003', 'Dr. Budi Santoso, M.Kom', 'budi.santoso@univ.ac.id', 'pass3', 'Jaringan Komputer', '2025-11-04 03:07:23'),
(4, 'D004', 'Dr. Maya Sari, M.Sc', 'maya.sari@univ.ac.id', 'pass4', 'Data Mining', '2025-11-04 03:07:23'),
(5, 'D005', 'Prof. Ahmad Rizki, Ph.D', 'ahmad.rizki@univ.ac.id', 'pass5', 'Machine Learning', '2025-11-04 03:07:23');

-- --------------------------------------------------------

--
-- Struktur dari tabel `history_proposal`
--

CREATE TABLE `history_proposal` (
  `history_id` int(11) NOT NULL,
  `proposal_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `tanggal_update` timestamp NOT NULL DEFAULT current_timestamp(),
  `catatan` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `history_proposal`
--

INSERT INTO `history_proposal` (`history_id`, `proposal_id`, `status_id`, `tanggal_update`, `catatan`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '2025-11-04 13:24:39', 'Status diperbarui menjadi Disetujui', '2025-11-04 13:24:39', '2025-11-04 13:24:39'),
(2, 2, 5, '2025-11-10 00:22:29', 'Feedback dari dosen: Harap perbaiki bagian metodologi.', '2025-11-10 00:22:29', '2025-11-10 00:22:29'),
(3, 3, 1, '2025-11-04 13:25:03', 'Proposal diajukan', '2025-11-04 13:25:03', '2025-11-04 13:25:03'),
(4, 4, 1, '2025-11-05 02:59:36', 'Proposal diajukan', '2025-11-05 02:59:36', '2025-11-05 02:59:36'),
(5, 5, 2, '2025-12-02 08:16:43', 'Proposal disetujui untuk tahap berikutnya', '2025-12-02 08:16:43', '2025-12-02 08:16:43');

-- --------------------------------------------------------

--
-- Struktur dari tabel `mahasiswa`
--

CREATE TABLE `mahasiswa` (
  `mahasiswa_id` int(11) NOT NULL,
  `nim` varchar(20) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `prodi` varchar(50) DEFAULT NULL,
  `angkatan` year(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `mahasiswa`
--

INSERT INTO `mahasiswa` (`mahasiswa_id`, `nim`, `nama`, `email`, `password`, `prodi`, `angkatan`) VALUES
(1, '2021001', 'Rina Susanti', 'rina.susanti@student.univ.ac.id', 'pw1', 'Teknik Informatika', '2021'),
(2, '2021002', 'Joko Prabowo', 'joko.prabowo@student.univ.ac.id', 'pw2', 'Sistem Informasi', '2021'),
(3, '2021003', 'Fitri Handayani', 'fitri.handayani@student.univ.ac.id', 'pw3', 'Teknik Komputer', '2021'),
(4, '2022001', 'Agung Prasetyo', 'agung.prasetyo@student.univ.ac.id', 'pw4', 'Teknik Informatika', '2022'),
(5, '2022002', 'Dewi Kartika', 'dewi.kartika@student.univ.ac.id', 'pw5', 'Sistem Informasi', '2022');

-- --------------------------------------------------------

--
-- Struktur dari tabel `pembimbing`
--

CREATE TABLE `pembimbing` (
  `pembimbing_id` int(11) NOT NULL,
  `proposal_id` int(11) NOT NULL,
  `dosen_id` int(11) NOT NULL,
  `jenis` enum('1','2') NOT NULL,
  `status` enum('aktif','selesai') DEFAULT 'aktif',
  `tanggal_mulai` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pembimbing`
--

INSERT INTO `pembimbing` (`pembimbing_id`, `proposal_id`, `dosen_id`, `jenis`, `status`, `tanggal_mulai`) VALUES
(1, 1, 1, '1', 'aktif', '2025-11-04'),
(2, 2, 2, '1', 'aktif', '2025-11-04'),
(3, 3, 3, '1', 'aktif', '2025-11-09'),
(4, 4, 4, '1', 'aktif', '2025-11-10'),
(5, 5, 5, '1', 'aktif', '2025-11-30');

-- --------------------------------------------------------

--
-- Struktur dari tabel `proposal`
--

CREATE TABLE `proposal` (
  `proposal_id` int(11) NOT NULL,
  `mahasiswa_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `judul` text NOT NULL,
  `abstrak` text DEFAULT NULL,
  `tanggal_ajuan` datetime DEFAULT NULL,
  `catatan` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `proposal`
--

INSERT INTO `proposal` (`proposal_id`, `mahasiswa_id`, `status_id`, `judul`, `abstrak`, `tanggal_ajuan`, `catatan`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'Sistem Informasi Manajemen Perpustakaan', 'Penelitian tentang pembangunan sistem informasi perpustakaan berbasis web dengan fitur katalog digital dan peminjaman online', '2025-08-15 10:30:00', 'Harap perbaiki bagian metodologi.', '2025-11-04 03:07:23', '2025-11-09 14:53:07'),
(2, 2, 5, 'Analisis Sentimen Media Sosial Menggunakan Machine Learning', 'Penelitian implementasi algoritma machine learning untuk analisis sentimen pada data media sosial Twitter', '2025-07-20 09:15:00', 'Proposal sudah bagus, namun perlu perbaikan pada bagian metodologi penelitian.', '2025-11-04 03:07:23', '2025-12-02 08:16:43'),
(3, 3, 1, 'Implementasi IoT untuk Smart Home System', 'Penelitian perancangan dan implementasi sistem smart home menggunakan teknologi Internet of Things', '2025-09-01 14:20:00', 'Sedang dalam tahap review oleh pembimbing', '2025-11-04 03:07:23', '2025-11-04 13:25:03'),
(4, 4, 1, 'Aplikasi Mobile E-Learning Berbasis Flutter', 'Pengembangan aplikasi mobile learning berbasis Flutter dengan fitur video streaming dan quiz interaktif', '2025-11-04 21:21:44', 'Harap diperiksa', '2025-11-04 13:21:44', '2025-11-04 13:21:44'),
(5, 5, 2, 'Sistem Deteksi Wajah Menggunakan Deep Learning', 'Implementasi algoritma deep learning untuk sistem deteksi dan pengenalan wajah real-time', '2025-11-04 21:21:44', 'Sudah disetujui untuk tahap berikutnya.', '2025-11-04 13:21:44', '2025-11-04 13:21:44');

--
-- Trigger `proposal`
--
DELIMITER $$
CREATE TRIGGER `tr_proposal_auto_tanggal` BEFORE INSERT ON `proposal` FOR EACH ROW BEGIN
   IF NEW.tanggal_ajuan IS NULL THEN
       SET NEW.tanggal_ajuan = NOW();
   END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_proposal_prevent_duplicate` BEFORE INSERT ON `proposal` FOR EACH ROW BEGIN
   DECLARE v_count INT;

   SELECT COUNT(*) INTO v_count
     FROM proposal
    WHERE mahasiswa_id = NEW.mahasiswa_id
      AND judul = NEW.judul;

   IF v_count > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proposal dengan judul yang sama sudah ada!';
   END IF;
END
$$
DELIMITER ;

-- ============================================
-- ADDITIONAL TRIGGERS (Database Improvements)
-- ============================================

-- Trigger: Auto-insert to History_Proposal saat proposal dibuat
DELIMITER $$
CREATE TRIGGER `tr_proposal_auto_history` AFTER INSERT ON `proposal` FOR EACH ROW BEGIN
    INSERT INTO history_proposal(proposal_id, status_id, catatan, created_at, updated_at)
    VALUES(NEW.proposal_id, NEW.status_id, 'Proposal diajukan', NOW(), NOW());
END
$$
DELIMITER ;

-- Trigger: Log history saat status proposal berubah
DELIMITER $$
CREATE TRIGGER `tr_proposal_status_change_history` AFTER UPDATE ON `proposal` FOR EACH ROW BEGIN
    IF OLD.status_id != NEW.status_id THEN
        INSERT INTO history_proposal(proposal_id, status_id, catatan, created_at, updated_at)
        VALUES(NEW.proposal_id, NEW.status_id, 
               CONCAT('Status berubah dari ', OLD.status_id, ' ke ', NEW.status_id), 
               NOW(), NOW());
    END IF;
END
$$
DELIMITER ;

-- Trigger: Validasi status transition proposal
DELIMITER $$
CREATE TRIGGER `tr_proposal_validate_status` BEFORE UPDATE ON `proposal` FOR EACH ROW BEGIN
    -- Status 1=Diajukan, 2=Review, 3=Disetujui, 4=Ditolak, 5=Perlu Revisi, 6=Selesai
    
    -- Validasi: Tidak bisa langsung dari Diajukan (1) ke Selesai (6)
    IF OLD.status_id = 1 AND NEW.status_id = 6 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tidak dapat mengubah status dari Diajukan langsung ke Selesai';
    END IF;
    
    -- Validasi: Jika sudah Ditolak (4), tidak bisa diubah lagi kecuali dihapus
    IF OLD.status_id = 4 AND NEW.status_id != 4 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Proposal yang ditolak tidak dapat diubah statusnya';
    END IF;
    
    -- Validasi: Jika sudah Selesai (6), tidak bisa diubah lagi
    IF OLD.status_id = 6 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Proposal yang sudah selesai tidak dapat diubah';
    END IF;
END
$$
DELIMITER ;

-- ============================================
-- TRIGGERS untuk mahasiswa
-- ============================================

-- Trigger: Validasi email format mahasiswa
DELIMITER $$
CREATE TRIGGER `tr_mahasiswa_validate_email` BEFORE INSERT ON `mahasiswa` FOR EACH ROW BEGIN
    IF NEW.email NOT LIKE '%@%' OR NEW.email NOT LIKE '%.%' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Format email tidak valid';
    END IF;
    
    IF LENGTH(NEW.password) < 6 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Password minimal 6 karakter';
    END IF;
END
$$
DELIMITER ;

-- Trigger: Prevent perubahan NIM/Email mahasiswa
DELIMITER $$
CREATE TRIGGER `tr_mahasiswa_update_timestamp` BEFORE UPDATE ON `mahasiswa` FOR EACH ROW BEGIN
    IF NEW.nim != OLD.nim OR NEW.email != OLD.email THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot change NIM or Email';
    END IF;
END
$$
DELIMITER ;

-- ============================================
-- TRIGGERS untuk dosen
-- ============================================

-- Trigger: Validasi email format dosen
DELIMITER $$
CREATE TRIGGER `tr_dosen_validate_email` BEFORE INSERT ON `dosen` FOR EACH ROW BEGIN
    IF NEW.email NOT LIKE '%@%' OR NEW.email NOT LIKE '%.%' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Format email tidak valid';
    END IF;
    
    IF LENGTH(NEW.password) < 6 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Password minimal 6 karakter';
    END IF;
END
$$
DELIMITER ;

-- Trigger: Prevent modify created_at dosen
DELIMITER $$
CREATE TRIGGER `tr_dosen_update_timestamp` BEFORE UPDATE ON `dosen` FOR EACH ROW BEGIN
    SET NEW.created_at = OLD.created_at;
END
$$
DELIMITER ;

-- ============================================
-- TRIGGERS untuk pembimbing
-- ============================================

-- Trigger: Validasi maksimal pembimbing
DELIMITER $$
CREATE TRIGGER `tr_pembimbing_validate_max` BEFORE INSERT ON `pembimbing` FOR EACH ROW BEGIN
    DECLARE v_count_jenis INT;
    DECLARE v_total_count INT;
    
    -- Cek apakah jenis pembimbing ini sudah ada
    SELECT COUNT(*) INTO v_count_jenis
    FROM pembimbing
    WHERE proposal_id = NEW.proposal_id
      AND jenis = NEW.jenis;
    
    IF v_count_jenis > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Pembimbing dengan jenis ini sudah ada untuk proposal ini';
    END IF;
    
    -- Cek total pembimbing tidak lebih dari 2
    SELECT COUNT(*) INTO v_total_count
    FROM pembimbing
    WHERE proposal_id = NEW.proposal_id;
    
    IF v_total_count >= 2 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Maksimal 2 pembimbing per proposal';
    END IF;
END
$$
DELIMITER ;

-- Trigger: Auto-set tanggal_mulai pembimbing
DELIMITER $$
CREATE TRIGGER `tr_pembimbing_auto_date` BEFORE INSERT ON `pembimbing` FOR EACH ROW BEGIN
    IF NEW.tanggal_mulai IS NULL THEN
        SET NEW.tanggal_mulai = CURDATE();
    END IF;
    IF NEW.status IS NULL THEN
        SET NEW.status = 'aktif';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `status_proposal`
--

CREATE TABLE `status_proposal` (
  `status_id` int(11) NOT NULL,
  `nama_status` varchar(50) NOT NULL,
  `urutan` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `status_proposal`
--

INSERT INTO `status_proposal` (`status_id`, `nama_status`, `urutan`) VALUES
(1, 'Diajukan', 1),
(2, 'Sedang Review', 2),
(3, 'Disetujui', 3),
(4, 'Ditolak', 4),
(5, 'Perlu Revisi', 5),
(6, 'Selesai', 6);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_admin_all_dosen`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_admin_all_dosen` (
`dosen_id` int(11)
,`nip` varchar(20)
,`nama` varchar(100)
,`email` varchar(100)
,`bidang_keahlian` varchar(50)
,`created_at` timestamp
,`jumlah_bimbingan_aktif` bigint(21)
,`status_bimbingan` varchar(14)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_admin_all_mahasiswa`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_admin_all_mahasiswa` (
`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama` varchar(100)
,`email` varchar(100)
,`prodi` varchar(50)
,`angkatan` year(4)
,`jumlah_pembimbing_aktif` bigint(21)
,`status_pembimbing` varchar(22)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_admin_all_proposal`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_admin_all_proposal` (
`proposal_id` int(11)
,`judul` text
,`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`nama_status` varchar(50)
,`tanggal_ajuan` datetime
,`updated_at` timestamp
,`pembimbing` mediumtext
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_dosen_proposal_detail`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_dosen_proposal_detail` (
`proposal_id` int(11)
,`judul` text
,`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`nama_status` varchar(50)
,`dosen_id` int(11)
,`jenis_pembimbing` enum('1','2')
,`status_pembimbing` enum('aktif','selesai')
,`tanggal_mulai` date
,`tanggal_ajuan` datetime
,`catatan` text
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_pembimbing_proposal`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_pembimbing_proposal` (
`dosen_id` int(11)
,`nama_dosen` varchar(100)
,`proposal_id` int(11)
,`judul` text
,`nama_mahasiswa` varchar(100)
,`jenis` enum('1','2')
,`status` enum('aktif','selesai')
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_bimbingan`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_proposal_bimbingan` (
`proposal_id` int(11)
,`judul` text
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`nama_status` varchar(50)
,`dosen_id` int(11)
,`jenis_pembimbing` enum('1','2')
,`status_pembimbing` enum('aktif','selesai')
,`tanggal_mulai` date
,`tanggal_ajuan` datetime
,`catatan` text
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_detail`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_proposal_detail` (
`proposal_id` int(11)
,`judul` text
,`abstrak` text
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`nama_status` varchar(50)
,`nama_pembimbing` mediumtext
,`tanggal_ajuan` datetime
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_status_feedback`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_proposal_status_feedback` (
`proposal_id` int(11)
,`judul` text
,`status_terkini` varchar(50)
,`feedback` text
,`tanggal_feedback` timestamp
,`dosen_pembimbing` varchar(100)
,`mahasiswa_id` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_status_summary_mahasiswa`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `vw_status_summary_mahasiswa` (
`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama` varchar(100)
,`nama_status` varchar(50)
,`jumlah_proposal` bigint(21)
);

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_admin_all_dosen`
--
DROP TABLE IF EXISTS `vw_admin_all_dosen`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_admin_all_dosen`  AS SELECT `d`.`dosen_id` AS `dosen_id`, `d`.`nip` AS `nip`, `d`.`nama` AS `nama`, `d`.`email` AS `email`, `d`.`bidang_keahlian` AS `bidang_keahlian`, `d`.`created_at` AS `created_at`, count(case when `pb`.`status` = 'aktif' then 1 end) AS `jumlah_bimbingan_aktif`, CASE WHEN count(case when `pb`.`status` = 'aktif' then 1 end) > 0 THEN 'Sudah Mengampu' ELSE 'Belum Mengampu' END AS `status_bimbingan` FROM (`dosen` `d` left join `pembimbing` `pb` on(`d`.`dosen_id` = `pb`.`dosen_id`)) GROUP BY `d`.`dosen_id`, `d`.`nip`, `d`.`nama`, `d`.`email`, `d`.`bidang_keahlian`, `d`.`created_at` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_admin_all_mahasiswa`
--
DROP TABLE IF EXISTS `vw_admin_all_mahasiswa`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_admin_all_mahasiswa`  AS SELECT `m`.`mahasiswa_id` AS `mahasiswa_id`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama`, `m`.`email` AS `email`, `m`.`prodi` AS `prodi`, `m`.`angkatan` AS `angkatan`, count(case when `pb`.`status` = 'aktif' then 1 end) AS `jumlah_pembimbing_aktif`, CASE WHEN count(case when `pb`.`status` = 'aktif' then 1 end) > 0 THEN 'Sudah Punya pembimbing' ELSE 'Belum Punya pembimbing' END AS `status_pembimbing` FROM ((`mahasiswa` `m` left join `proposal` `p` on(`m`.`mahasiswa_id` = `p`.`mahasiswa_id`)) left join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) GROUP BY `m`.`mahasiswa_id`, `m`.`nim`, `m`.`nama`, `m`.`email`, `m`.`prodi`, `m`.`angkatan` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_admin_all_proposal`
--
DROP TABLE IF EXISTS `vw_admin_all_proposal`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_admin_all_proposal`  AS SELECT `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `m`.`mahasiswa_id` AS `mahasiswa_id`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama_mahasiswa`, `sp`.`nama_status` AS `nama_status`, `p`.`tanggal_ajuan` AS `tanggal_ajuan`, `p`.`updated_at` AS `updated_at`, group_concat(distinct concat(`d`.`nama`,' (',`pb`.`jenis`,')') separator ', ') AS `pembimbing` FROM ((((`proposal` `p` join `mahasiswa` `m` on(`p`.`mahasiswa_id` = `m`.`mahasiswa_id`)) join `status_proposal` `sp` on(`p`.`status_id` = `sp`.`status_id`)) left join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) left join `dosen` `d` on(`pb`.`dosen_id` = `d`.`dosen_id`)) GROUP BY `p`.`proposal_id`, `p`.`judul`, `m`.`mahasiswa_id`, `m`.`nim`, `m`.`nama`, `sp`.`nama_status`, `p`.`tanggal_ajuan`, `p`.`updated_at` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_dosen_proposal_detail`
--
DROP TABLE IF EXISTS `vw_dosen_proposal_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_dosen_proposal_detail`  AS SELECT `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `p`.`mahasiswa_id` AS `mahasiswa_id`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama_mahasiswa`, `sp`.`nama_status` AS `nama_status`, `pb`.`dosen_id` AS `dosen_id`, `pb`.`jenis` AS `jenis_pembimbing`, `pb`.`status` AS `status_pembimbing`, `pb`.`tanggal_mulai` AS `tanggal_mulai`, `p`.`tanggal_ajuan` AS `tanggal_ajuan`, `p`.`catatan` AS `catatan` FROM ((((`proposal` `p` join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) join `dosen` `d` on(`pb`.`dosen_id` = `d`.`dosen_id`)) join `mahasiswa` `m` on(`p`.`mahasiswa_id` = `m`.`mahasiswa_id`)) join `status_proposal` `sp` on(`p`.`status_id` = `sp`.`status_id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_pembimbing_proposal`
--
DROP TABLE IF EXISTS `vw_pembimbing_proposal`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_pembimbing_proposal`  AS SELECT `d`.`dosen_id` AS `dosen_id`, `d`.`nama` AS `nama_dosen`, `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `m`.`nama` AS `nama_mahasiswa`, `pb`.`jenis` AS `jenis`, `pb`.`status` AS `status` FROM (((`dosen` `d` join `pembimbing` `pb` on(`d`.`dosen_id` = `pb`.`dosen_id`)) join `proposal` `p` on(`pb`.`proposal_id` = `p`.`proposal_id`)) join `mahasiswa` `m` on(`p`.`mahasiswa_id` = `m`.`mahasiswa_id`)) ORDER BY `d`.`nama` ASC, `p`.`tanggal_ajuan` DESC ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_bimbingan`
--
DROP TABLE IF EXISTS `vw_proposal_bimbingan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_bimbingan`  AS SELECT `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama_mahasiswa`, `sp`.`nama_status` AS `nama_status`, `pb`.`dosen_id` AS `dosen_id`, `pb`.`jenis` AS `jenis_pembimbing`, `pb`.`status` AS `status_pembimbing`, `pb`.`tanggal_mulai` AS `tanggal_mulai`, `p`.`tanggal_ajuan` AS `tanggal_ajuan`, `p`.`catatan` AS `catatan` FROM ((((`proposal` `p` join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) join `dosen` `d` on(`pb`.`dosen_id` = `d`.`dosen_id`)) join `mahasiswa` `m` on(`p`.`mahasiswa_id` = `m`.`mahasiswa_id`)) join `status_proposal` `sp` on(`p`.`status_id` = `sp`.`status_id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_detail`
--
DROP TABLE IF EXISTS `vw_proposal_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_detail`  AS SELECT `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `p`.`abstrak` AS `abstrak`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama_mahasiswa`, `sp`.`nama_status` AS `nama_status`, group_concat(distinct `d`.`nama` separator ', ') AS `nama_pembimbing`, `p`.`tanggal_ajuan` AS `tanggal_ajuan`, `p`.`updated_at` AS `updated_at` FROM ((((`proposal` `p` join `mahasiswa` `m` on(`p`.`mahasiswa_id` = `m`.`mahasiswa_id`)) join `status_proposal` `sp` on(`p`.`status_id` = `sp`.`status_id`)) left join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) left join `dosen` `d` on(`pb`.`dosen_id` = `d`.`dosen_id`)) GROUP BY `p`.`proposal_id`, `p`.`judul`, `p`.`abstrak`, `m`.`nim`, `m`.`nama`, `sp`.`nama_status`, `p`.`tanggal_ajuan`, `p`.`updated_at` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_status_feedback`
--
DROP TABLE IF EXISTS `vw_proposal_status_feedback`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_status_feedback`  AS SELECT `p`.`proposal_id` AS `proposal_id`, `p`.`judul` AS `judul`, `fn_get_current_status`(`p`.`proposal_id`) AS `status_terkini`, `h`.`catatan` AS `feedback`, `h`.`created_at` AS `tanggal_feedback`, `d`.`nama` AS `dosen_pembimbing`, `p`.`mahasiswa_id` AS `mahasiswa_id` FROM (((`proposal` `p` left join `history_proposal` `h` on(`p`.`proposal_id` = `h`.`proposal_id`)) left join `pembimbing` `pb` on(`p`.`proposal_id` = `pb`.`proposal_id`)) left join `dosen` `d` on(`pb`.`dosen_id` = `d`.`dosen_id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_status_summary_mahasiswa`
--
DROP TABLE IF EXISTS `vw_status_summary_mahasiswa`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_status_summary_mahasiswa`  AS SELECT `m`.`mahasiswa_id` AS `mahasiswa_id`, `m`.`nim` AS `nim`, `m`.`nama` AS `nama`, `sp`.`nama_status` AS `nama_status`, count(`p`.`proposal_id`) AS `jumlah_proposal` FROM ((`mahasiswa` `m` left join `proposal` `p` on(`m`.`mahasiswa_id` = `p`.`mahasiswa_id`)) left join `status_proposal` `sp` on(`p`.`status_id` = `sp`.`status_id`)) GROUP BY `m`.`mahasiswa_id`, `m`.`nim`, `m`.`nama`, `sp`.`nama_status` ;

-- --------------------------------------------------------

-- ============================================
-- ADDITIONAL VIEWS (Database Improvements)
-- ============================================

--
-- Stand-in struktur untuk tampilan `vw_mahasiswa_proposals`
--
CREATE TABLE `vw_mahasiswa_proposals` (
`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`proposal_id` int(11)
,`judul` text
,`nama_status` varchar(50)
,`tanggal_ajuan` datetime
,`umur_hari` int(11)
,`pembimbing` varchar(500)
,`kelengkapan` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_dosen_statistics`
--
CREATE TABLE `vw_dosen_statistics` (
`dosen_id` int(11)
,`nip` varchar(20)
,`nama` varchar(100)
,`bidang_keahlian` varchar(50)
,`total_bimbingan_aktif` int(11)
,`total_bimbingan_selesai` bigint(21)
,`beban_kerja` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_timeline`
--
CREATE TABLE `vw_proposal_timeline` (
`proposal_id` int(11)
,`judul` text
,`mahasiswa_id` int(11)
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`status_pertama` varchar(50)
,`status_terkini` varchar(50)
,`tanggal_ajuan` datetime
,`tanggal_update_terakhir` timestamp
,`total_perubahan_status` bigint(21)
,`durasi_hari` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_overdue_proposals`
--
CREATE TABLE `vw_overdue_proposals` (
`proposal_id` int(11)
,`judul` text
,`nim` varchar(20)
,`nama_mahasiswa` varchar(100)
,`nama_status` varchar(50)
,`tanggal_ajuan` datetime
,`hari_tanpa_update` int(11)
,`pembimbing` varchar(500)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_top_pembimbing`
--
CREATE TABLE `vw_top_pembimbing` (
`dosen_id` int(11)
,`nip` varchar(20)
,`nama` varchar(100)
,`bidang_keahlian` varchar(50)
,`total_bimbingan` bigint(21)
,`bimbingan_aktif` bigint(21)
,`bimbingan_selesai` bigint(21)
,`ranking` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_summary_by_prodi`
--
CREATE TABLE `vw_proposal_summary_by_prodi` (
`prodi` varchar(50)
,`total_mahasiswa` bigint(21)
,`total_proposal` bigint(21)
,`proposal_diajukan` bigint(21)
,`proposal_review` bigint(21)
,`proposal_disetujui` bigint(21)
,`proposal_ditolak` bigint(21)
,`proposal_revisi` bigint(21)
,`proposal_selesai` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `vw_proposal_summary_by_year`
--
CREATE TABLE `vw_proposal_summary_by_year` (
`angkatan` year(4)
,`total_mahasiswa` bigint(21)
,`total_proposal` bigint(21)
,`proposal_diajukan` bigint(21)
,`proposal_review` bigint(21)
,`proposal_disetujui` bigint(21)
,`proposal_ditolak` bigint(21)
,`proposal_revisi` bigint(21)
,`proposal_selesai` bigint(21)
);

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_mahasiswa_proposals`
--
DROP TABLE IF EXISTS `vw_mahasiswa_proposals`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_mahasiswa_proposals` AS
SELECT 
    m.mahasiswa_id,
    m.nim,
    m.nama AS nama_mahasiswa,
    p.proposal_id,
    p.judul,
    sp.nama_status,
    p.tanggal_ajuan,
    fn_get_proposal_age_days(p.proposal_id) AS umur_hari,
    fn_get_pembimbing_names(p.proposal_id) AS pembimbing,
    fn_check_proposal_completeness(p.proposal_id) AS kelengkapan
FROM mahasiswa m
LEFT JOIN proposal p ON m.mahasiswa_id = p.mahasiswa_id
LEFT JOIN status_proposal sp ON p.status_id = sp.status_id;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_dosen_statistics`
--
DROP TABLE IF EXISTS `vw_dosen_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_dosen_statistics` AS
SELECT 
    d.dosen_id,
    d.nip,
    d.nama,
    d.bidang_keahlian,
    fn_count_dosen_bimbingan(d.dosen_id) AS total_bimbingan_aktif,
    (SELECT COUNT(*) FROM pembimbing WHERE dosen_id = d.dosen_id AND status = 'selesai') AS total_bimbingan_selesai,
    fn_get_dosen_workload(d.dosen_id) AS beban_kerja
FROM dosen d;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_timeline`
--
DROP TABLE IF EXISTS `vw_proposal_timeline`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_timeline` AS
SELECT 
    p.proposal_id,
    p.judul,
    p.mahasiswa_id,
    m.nim,
    m.nama AS nama_mahasiswa,
    (SELECT sp2.nama_status FROM history_proposal h2 
     JOIN status_proposal sp2 ON h2.status_id = sp2.status_id 
     WHERE h2.proposal_id = p.proposal_id 
     ORDER BY h2.created_at ASC LIMIT 1) AS status_pertama,
    sp.nama_status AS status_terkini,
    p.tanggal_ajuan,
    p.updated_at AS tanggal_update_terakhir,
    (SELECT COUNT(*) FROM history_proposal WHERE proposal_id = p.proposal_id) AS total_perubahan_status,
    fn_get_proposal_age_days(p.proposal_id) AS durasi_hari
FROM proposal p
JOIN mahasiswa m ON p.mahasiswa_id = m.mahasiswa_id
JOIN status_proposal sp ON p.status_id = sp.status_id;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_overdue_proposals`
--
DROP TABLE IF EXISTS `vw_overdue_proposals`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_overdue_proposals` AS
SELECT 
    p.proposal_id,
    p.judul,
    m.nim,
    m.nama AS nama_mahasiswa,
    sp.nama_status,
    p.tanggal_ajuan,
    DATEDIFF(NOW(), p.updated_at) AS hari_tanpa_update,
    fn_get_pembimbing_names(p.proposal_id) AS pembimbing
FROM proposal p
JOIN mahasiswa m ON p.mahasiswa_id = m.mahasiswa_id
JOIN status_proposal sp ON p.status_id = sp.status_id
WHERE DATEDIFF(NOW(), p.updated_at) > 30
  AND p.status_id NOT IN (3, 4, 6)
ORDER BY hari_tanpa_update DESC;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_top_pembimbing`
--
DROP TABLE IF EXISTS `vw_top_pembimbing`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_top_pembimbing` AS
SELECT 
    d.dosen_id,
    d.nip,
    d.nama,
    d.bidang_keahlian,
    COUNT(pb.pembimbing_id) AS total_bimbingan,
    SUM(CASE WHEN pb.status = 'aktif' THEN 1 ELSE 0 END) AS bimbingan_aktif,
    SUM(CASE WHEN pb.status = 'selesai' THEN 1 ELSE 0 END) AS bimbingan_selesai,
    DENSE_RANK() OVER (ORDER BY COUNT(pb.pembimbing_id) DESC) AS ranking
FROM dosen d
LEFT JOIN pembimbing pb ON d.dosen_id = pb.dosen_id
GROUP BY d.dosen_id, d.nip, d.nama, d.bidang_keahlian
ORDER BY total_bimbingan DESC;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_summary_by_prodi`
--
DROP TABLE IF EXISTS `vw_proposal_summary_by_prodi`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_summary_by_prodi` AS
SELECT 
    m.prodi,
    COUNT(DISTINCT m.mahasiswa_id) AS total_mahasiswa,
    COUNT(p.proposal_id) AS total_proposal,
    SUM(CASE WHEN p.status_id = 1 THEN 1 ELSE 0 END) AS proposal_diajukan,
    SUM(CASE WHEN p.status_id = 2 THEN 1 ELSE 0 END) AS proposal_review,
    SUM(CASE WHEN p.status_id = 3 THEN 1 ELSE 0 END) AS proposal_disetujui,
    SUM(CASE WHEN p.status_id = 4 THEN 1 ELSE 0 END) AS proposal_ditolak,
    SUM(CASE WHEN p.status_id = 5 THEN 1 ELSE 0 END) AS proposal_revisi,
    SUM(CASE WHEN p.status_id = 6 THEN 1 ELSE 0 END) AS proposal_selesai
FROM mahasiswa m
LEFT JOIN proposal p ON m.mahasiswa_id = p.mahasiswa_id
GROUP BY m.prodi;

-- --------------------------------------------------------

--
-- Struktur untuk view `vw_proposal_summary_by_year`
--
DROP TABLE IF EXISTS `vw_proposal_summary_by_year`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_proposal_summary_by_year` AS
SELECT 
    m.angkatan,
    COUNT(DISTINCT m.mahasiswa_id) AS total_mahasiswa,
    COUNT(p.proposal_id) AS total_proposal,
    SUM(CASE WHEN p.status_id = 1 THEN 1 ELSE 0 END) AS proposal_diajukan,
    SUM(CASE WHEN p.status_id = 2 THEN 1 ELSE 0 END) AS proposal_review,
    SUM(CASE WHEN p.status_id = 3 THEN 1 ELSE 0 END) AS proposal_disetujui,
    SUM(CASE WHEN p.status_id = 4 THEN 1 ELSE 0 END) AS proposal_ditolak,
    SUM(CASE WHEN p.status_id = 5 THEN 1 ELSE 0 END) AS proposal_revisi,
    SUM(CASE WHEN p.status_id = 6 THEN 1 ELSE 0 END) AS proposal_selesai
FROM mahasiswa m
LEFT JOIN proposal p ON m.mahasiswa_id = p.mahasiswa_id
GROUP BY m.angkatan
ORDER BY m.angkatan DESC;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indeks untuk tabel `dosen`
--
ALTER TABLE `dosen`
  ADD PRIMARY KEY (`dosen_id`),
  ADD UNIQUE KEY `nip` (`nip`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indeks untuk tabel `history_proposal`
--
ALTER TABLE `history_proposal`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `proposal_id` (`proposal_id`),
  ADD KEY `status_id` (`status_id`);

--
-- Indeks untuk tabel `mahasiswa`
--
ALTER TABLE `mahasiswa`
  ADD PRIMARY KEY (`mahasiswa_id`),
  ADD UNIQUE KEY `nim` (`nim`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indeks untuk tabel `pembimbing`
--
ALTER TABLE `pembimbing`
  ADD PRIMARY KEY (`pembimbing_id`),
  ADD KEY `proposal_id` (`proposal_id`),
  ADD KEY `dosen_id` (`dosen_id`);

--
-- Indeks untuk tabel `proposal`
--
ALTER TABLE `proposal`
  ADD PRIMARY KEY (`proposal_id`),
  ADD KEY `mahasiswa_id` (`mahasiswa_id`),
  ADD KEY `status_id` (`status_id`);

--
-- Indeks untuk tabel `status_proposal`
--
ALTER TABLE `status_proposal`
  ADD PRIMARY KEY (`status_id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `admin`
--
ALTER TABLE `admin`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT untuk tabel `dosen`
--
ALTER TABLE `dosen`
  MODIFY `dosen_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT untuk tabel `history_proposal`
--
ALTER TABLE `history_proposal`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT untuk tabel `mahasiswa`
--
ALTER TABLE `mahasiswa`
  MODIFY `mahasiswa_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT untuk tabel `pembimbing`
--
ALTER TABLE `pembimbing`
  MODIFY `pembimbing_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `proposal`
--
ALTER TABLE `proposal`
  MODIFY `proposal_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT untuk tabel `status_proposal`
--
ALTER TABLE `status_proposal`
  MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `history_proposal`
--
ALTER TABLE `history_proposal`
  ADD CONSTRAINT `history_proposal_ibfk_1` FOREIGN KEY (`proposal_id`) REFERENCES `proposal` (`proposal_id`),
  ADD CONSTRAINT `history_proposal_ibfk_2` FOREIGN KEY (`status_id`) REFERENCES `status_proposal` (`status_id`);

--
-- Ketidakleluasaan untuk tabel `pembimbing`
--
ALTER TABLE `pembimbing`
  ADD CONSTRAINT `pembimbing_ibfk_1` FOREIGN KEY (`proposal_id`) REFERENCES `proposal` (`proposal_id`),
  ADD CONSTRAINT `pembimbing_ibfk_2` FOREIGN KEY (`dosen_id`) REFERENCES `dosen` (`dosen_id`);

--
-- Ketidakleluasaan untuk tabel `proposal`
--
ALTER TABLE `proposal`
  ADD CONSTRAINT `proposal_ibfk_1` FOREIGN KEY (`mahasiswa_id`) REFERENCES `mahasiswa` (`mahasiswa_id`),
  ADD CONSTRAINT `proposal_ibfk_2` FOREIGN KEY (`status_id`) REFERENCES `status_proposal` (`status_id`);

-- ============================================
-- ADDITIONAL INDEXES (Database Improvements)
-- Performance Optimization
-- ============================================

-- Index pada proposal untuk sorting dan filtering
CREATE INDEX `idx_proposal_tanggal_ajuan` ON `proposal`(`tanggal_ajuan`);
CREATE INDEX `idx_proposal_status_mahasiswa` ON `proposal`(`status_id`, `mahasiswa_id`);
CREATE INDEX `idx_proposal_updated_at` ON `proposal`(`updated_at`);

-- Index pada History_Proposal untuk timeline
CREATE INDEX `idx_history_proposal_created` ON `history_proposal`(`proposal_id`, `created_at`);
CREATE INDEX `idx_history_status` ON `history_proposal`(`status_id`);

-- Index pada pembimbing untuk query bimbingan aktif
CREATE INDEX `idx_pembimbing_dosen_status` ON `pembimbing`(`dosen_id`, `status`);
CREATE INDEX `idx_pembimbing_proposal_jenis` ON `pembimbing`(`proposal_id`, `jenis`);

-- Index pada mahasiswa untuk filtering
CREATE INDEX `idx_mahasiswa_angkatan` ON `mahasiswa`(`angkatan`);
CREATE INDEX `idx_mahasiswa_prodi` ON `mahasiswa`(`prodi`);

-- Index pada dosen untuk filtering
CREATE INDEX `idx_dosen_bidang` ON `dosen`(`bidang_keahlian`);

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
