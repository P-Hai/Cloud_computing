CREATE DATABASE IF NOT EXISTS studentdb;
USE studentdb;

CREATE TABLE IF NOT EXISTS students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id VARCHAR(10) UNIQUE NOT NULL,
    fullname VARCHAR(100) NOT NULL,
    dob DATE,
    major VARCHAR(50),
    gpa DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (student_id, fullname, dob, major, gpa) VALUES
('SV001', 'Nguyễn Văn An', '2003-05-15', 'Công nghệ thông tin', 3.50),
('SV002', 'Trần Thị Bình', '2003-08-20', 'Khoa học dữ liệu', 3.80),
('SV003', 'Lê Văn Cường', '2003-03-10', 'An toàn thông tin', 3.60),
('SV004', 'Phạm Thị Dung', '2003-11-25', 'Trí tuệ nhân tạo', 3.90),
('SV005', 'Hoàng Văn Em', '2003-07-08', 'Công nghệ phần mềm', 3.70);