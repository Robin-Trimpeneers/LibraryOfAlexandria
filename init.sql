-- Use double backslashes for literal backslash in password
GRANT ALL PRIVILEGES ON bookapp.* TO 'appuser'@'%';
ALTER USER 'appuser'@'%' IDENTIFIED WITH mysql_native_password BY q[M}V+_QdOJ3Ljp,1cwZhz|r;
FLUSH PRIVILEGES;