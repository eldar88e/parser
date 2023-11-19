class ApplicationRecord < ActiveRecord::Base
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE'),
                       username: ENV.fetch('USERNAME'),
                       password: ENV.fetch('PASSWORD'))

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end
