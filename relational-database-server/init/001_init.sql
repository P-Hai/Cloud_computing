CREATE DATABASE IF NOT EXISTS minicloud;
USE minicloud;

CREATE TABLE IF NOT EXISTS notes(
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO notes(title, content) VALUES 
  ('Hello from MariaDB!', 'This is the first note in MyMiniCloud system'),
  ('Welcome', 'Welcome to the database server'),
  ('System Ready', 'All systems operational');