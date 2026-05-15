class CreateSchema < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE SCHEMA IF NOT EXISTS mollika;"
  end

  def down
    execute "DROP SCHEMA IF EXISTS mollika CASCADE;"
  end
end
