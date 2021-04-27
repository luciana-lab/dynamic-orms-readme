require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

#takes the name of the class (self)
#turns it into a string (to_s)
#downcase the string and then make it plural
#pluralize method is provided by active_support/inflector code, required at the top
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    #<a href="#resources">PRAGMA</a> will return an array of hashes describing the table itself - because of 'results_as_hash'
    #each hash contain info about one column
    sql = "pragma table_info('#{table_name}')"

    #the only thing we're grabing out is the name of each column
    #each hash has a 'name' key that points to a value of the column name (e.g. "name"=> "id", "name"=>"name", "name"=> "album")
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end

    #compact is called just to be safe and get rid of any 'nil' values
    column_names.compact
  end

  #iterate over the column names stored in the 'column_names' class method
  #set an 'attr_accessor' for each one
  #convert the column name string into a symbol with 'to_sym' method (attr_accessor must be named with symbols)
  #a reader and a writer for each column name is dynamically created (metaprogramming)
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  #take an argument of 'options' which defaults to an empty hash
  #we expect the 'new' to be called with a hash
  #iterate over the 'options' hash
  #use the 'send' method to interpolate the name of each hash key as a method that set equal to that key's value
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #'save' is an instance method (self refer to the instance of the class, not the class itself)
  #in order to use a class method inside an instance method, we create this method below
  def table_name_for_insert
    self.class.table_name
  end

  #iterate over the column names stored in 'self.column_names'
  #use the 'send' method with each individual column name to invoke the method by that same name and capture the return value
  #unless that value is 'nil' (id)
  #wrap the return value in a string
  #each individual value enclosed in single quotes, inside the string
  #comma separate values for SQL statement
  #join the values array into a string
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  #not include the 'id' column name or value, removed it
  #column names returned by the 'self.class.column.names' is an array. Turn them into a comma separated list, contained in a string
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  #use the 'self.table_name' class method to return the table name associated
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



