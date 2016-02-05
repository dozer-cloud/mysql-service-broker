require_relative '../../lib/mysql_broker/mysql_helper'

describe MysqlHelper do
  let(:db_url) { ENV['DATABASE_URL'] || 'mysql2://root:password@localhost/mysql' }
  subject { MysqlHelper.new(db_url) }
  let(:db) { subject.send(:connection) }
  let(:db_name) { SecureRandom.uuid }
  let(:db_user) { SecureRandom.uuid }
  let(:created_databases) do
    db.query "SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME LIKE 'MSB_%'"
  end
  let(:created_users) do
    db.query "SELECT * FROM MYSQL.USER WHERE User LIKE 'MSB_%'"
  end

  after do
    created_databases.map { |r| r['SCHEMA_NAME'] }.each do |name|
      db.query "DROP DATABASE #{name}"
    end

    created_users.map { |r| r['User'] }.each do |name|
      db.query "DROP USER #{name}"
    end
  end

  describe '#create_database' do
    it 'can create a database' do
      expect{ subject.create_database(db_name) }.to_not raise_error
      expect(created_databases.count).to eq 1
    end
  end

  describe '#delete_database' do
    before { subject.create_database(db_name) }

    it 'can delete a database' do
      expect{ subject.delete_database(db_name) }.to_not raise_error
      expect(created_databases.count).to eq 0
    end
  end

  describe '#create_user' do
    before { subject.create_database(db_name) }

    it 'can create a user' do
      expect{ subject.create_user(db_user, db_name) }.to_not raise_error
      expect(created_users.count).to eq 1
    end
  end

  describe '#delete_user' do
    before do
      subject.create_database(db_name)
      subject.create_user(db_user, db_name)
    end

    it 'can delete a user' do
      expect{ subject.delete_user(db_user) }.to_not raise_error
      expect(created_users.count).to eq 0
    end
  end
end
