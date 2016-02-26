require_relative '../service_broker_api'
require_relative 'mysql_helper'

class MysqlBroker < ServiceBrokerApi
  def create_instance(instance_name)
    service.create_database(instance_name)
  end

  def bind_instance(binding_name, instance_name)
    service.create_user(binding_name, instance_name)
  end

  def delete_binding(binding_name)
    service.delete_user(binding_name)
  end

  def delete_instance(instance_name)
    service.delete_database(instance_name)
  end

  def service
    MysqlHelper.new(ENV['DATABASE_URL'])
  end

  def ServiceBrokerApi.app_settings
    @app_settings ||= {
      'catalog' => YAML.load_file('config/catalog.yml'),
      'basic_auth' => {
        'username' => ENV['BROKER_USERNAME'],
        'password' => ENV['BROKER_PASSWORD']
      }
    }
  end
end
