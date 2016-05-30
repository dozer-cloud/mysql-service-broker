require 'mysql2'
require 'securerandom'

class MysqlHelper
  PREFIX = 'MSB_'

  def initialize(database_url)
    uri = URI.parse(database_url)
    @username = uri.user
    @password = uri.password
    @hostname = uri.hostname
    @port     = uri.port
  end

  def create_database(db_name)
    safe_db_name = safe_name(db_name)
    run_safely do
      connection.query("CREATE DATABASE #{safe_db_name}")
    end
    "http://#{@hostname}:#{@port}/databases/#{db_name}"
  end

  def create_user(username, db_name)
    safe_db_name = safe_name(db_name)
    safe_username = safe_name(username)
    password = SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
    run_safely do
      connection.query("CREATE USER '#{safe_username}'@'%' IDENTIFIED BY '#{password}'")
      connection.query("GRANT ALL ON #{safe_db_name}.* TO '#{safe_username}'@'%'")
    end
    {
      hostname: @hostname,
      port: @port,
      db_name: db_name,
      username: safe_username,
      password: password,
      uri: "mysql://#{safe_username}:#{password}@#{@hostname}:#{@port}/#{safe_db_name}",
      jdbcUrl: "jdbc:mysql://#{safe_username}:#{password}@#{@hostname}:#{@port}/#{safe_db_name}"
    }
  end

  def delete_user(username)
    safe_username = safe_name(username)
    run_safely do
      connection.query("DROP USER #{safe_username}")
    end
  end

  def delete_database(db_name)
    safe_db_name = safe_name(db_name)
    run_safely do
      connection.query("DROP DATABASE #{safe_db_name}")
    end

    orphaned_users_for(safe_db_name).each do |user|
      run_safely do
        connection.query("DROP USER #{user}")
      end
    end
  end

  private

  def orphaned_users_for(db)
    run_safely do
      connection.query("SELECT user FROM mysql.db WHERE db = '#{db}'")
        .map { |r| r['user']  }
    end
  end

  def run_safely
    begin
      yield if block_given?
    rescue => e
      if e.message.match /database \".*\" already exists/
        raise ServiceInstanceAlreadyExistsError
      elsif e.message.match /database \".*\" does not exist/
        raise ServiceInstanceDoesNotExistError
      elsif e.message.match /role \".*\" already exists/
        raise BindingAlreadyExistsError
      elsif e.message.match /role \".*\" does not exist/
        raise BindingDoesNotExistError
      elsif e.message.match /could not connect/
        raise ServerNotReachableError
      else
        raise StandardError, e.message
      end
    end
  end

  def connection
    @conn ||= Mysql2::Client.new(
      username: @username,
      password: @password,
      host: @hostname,
      port: @port
    )
  end

  def safe_name(name)
    PREFIX + Digest::MD5.base64digest(name).gsub(/[^a-zA-Z0-9]+/, '')[0...12]
  end
end
