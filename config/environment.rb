require 'sqlite3'

#1. Create the database
DB = {:conn => SQLite3::Database.new("db/songs.db")}

#2. Drop songs to avoid an error
DB[:conn].execute("DROP TABLE IF EXISTS songs")

#3. Create the songs table
sql = <<-SQL
  CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY,
  name TEXT,
  album TEXT
  )
SQL

DB[:conn].execute(sql)
DB[:conn].results_as_hash = true
#result_as_hash is a SQLite3-Ruby gem
  #return the database row as a hash, not as an array