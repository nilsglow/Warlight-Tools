require 'yaml'
settings = YAML::load_file "config/production.yml"

puts settings['auth']['email']
