require 'thor'
require 'yaml'
require 'active_record'

module Mozaic
  class Command < Thor
    option :d
    option :u
    option :p
    option :dest, required: true

    desc "dump", "dump"
    def dump(yaml)
      @setting = Setting.new(yaml, options)
      connect_db
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(@setting.db_setting_hash, options[:dest])
      @setting.table_settings.each do |table_setting|
        table = Table.new(table_setting[:name])
        next if table.records.blank?
        masked_records = Mask.new(table.records, table_setting[:columns]).mask
        query = BulkInsert.generate(table.name, masked_records, table.columns, @setting)
        File.open(options[:dest], 'a') do |f|
          f.puts "\n"
          f.puts query
          f.puts "\n"
        end
      end
    end

    private

    def connect_db
      ActiveRecord::Base.establish_connection(@setting.db_setting_hash)
    end
  end
end
