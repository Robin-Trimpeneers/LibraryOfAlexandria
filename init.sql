-- Initialize database for Library of Alexandria
CREATE DATABASE IF NOT EXISTS librarydb;
USE librarydb;

-- Create user if not exists
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'q[M}V+_QdOJ3Ljp,1cwZhz|r';

-- Grant privileges
GRANT ALL PRIVILEGES ON librarydb.* TO 'appuser'@'%';
ALTER USER 'appuser'@'%' IDENTIFIED WITH mysql_native_password BY 'q[M}V+_QdOJ3Ljp,1cwZhz|r';
FLUSH PRIVILEGES;