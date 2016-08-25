require 'yaml'

require 'WarLightSVG'
require 'WarLightAPIClient'
require 'geometry'

module WarLight
  def load_settings
    settings = "config/production.yml"
    abort "Settings file #{settings} not found!" if !File.exist? settings
    
    settings = YAML::load_file(settings)
    
    # check all required settings are there
    ["svgfile", "mapid", "email", "APIToken"].each {|key|
      abort "#{key} not found in settings!" if !settings.key?(key) or !settings[key]
    }
    
    abort "File #{settings["svgfile"]} not found!" if !File.exist? settings["svgfile"]

    settings
  end
end