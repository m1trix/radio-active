#!/bin/bash

# mysql -u root -p <<-EOF
#     CREATE DATABASE IF NOT EXISTS testdb;
#     CREATE USER IF NOT EXISTS 'radio_test'@'localhost' IDENTIFIED BY 'test';
#     GRANT ALL PRIVILEGES ON testdb.* TO 'radio_test'@'localhost';
# EOF
rspec ./spec/root_spec.rb --color --format documentation <<< 'abcd'
