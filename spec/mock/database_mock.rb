require 'radioactive/database'
require 'mock/logger_mock'

module Radioactive
  class Database
    def self.bind_test
      bind(
        database: 'testdb:localhost',
        user: 'radio_test',
        password: 'test'
      )
    end
  end
end

Radioactive::Database.bind_test