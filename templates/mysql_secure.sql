DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('<%= @root_password %>');

CREATE USER 'sstuser'@'localhost' IDENTIFIED BY '<%= @sst_password %>';
GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';

CREATE USER '<%= @monitor_username %>'@'localhost' IDENTIFIED BY '<%= @monitor_password %>';
GRANT PROCESS,REPLICATION CLIENT ON *.* TO '<%= @monitor_username %>'@'localhost';
GRANT SELECT ON test.* TO '<%= @monitor_username %>'@'localhost';
CREATE TABLE IF NOT EXISTS `test`.`nagios` (
  `id` varchar(255) DEFAULT NULL
) ENGINE = InnoDB;
INSERT INTO test.nagios (id) VALUES ('placeholder');
GRANT UPDATE ON test.nagios TO '<%= @monitor_username %>'@'localhost';

FLUSH PRIVILEGES;
