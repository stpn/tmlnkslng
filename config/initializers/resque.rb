

rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'production'
resque_config = YAML.load_file(rails_root + '/config/resque.yml')
Resque.redis = resque_config[rails_env]


# ENV["REDISTOGO_URL"] ||= "redis://stpn:f52d99d85d328211a9d730ef145c6db9@panga.redistogo.com:9812/"
# uri = URI.parse(ENV["REDISTOGO_URL"])
# Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)





Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60) # 24hrs in seconds

Dir["#{Rails.root}/app/workers/*.rb"].each { |file| require file }

