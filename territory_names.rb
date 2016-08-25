# coding: utf-8

require 'yaml'

$LOAD_PATH.unshift File.dirname($0)+"/tools"
# from ./tools/
require 'warlight'



include WarLight
settings = WarLight::load_settings


puts 'Working... this may take some time. Go have a cup of tea or something.'
$talktome = true

svg = WarLightSVG.new(settings["svgfile"])
names = svg.territory_names()

# add host and path to settings
settings[:host] = "warlight.net"
settings[:path] = '/API/SetMapDetails'
client = WarLightAPIClient.new(settings)

# add all commands into client
names.each_pair do |id, name|
  client.add_command({
    "command" => 'setTerritoryName', id: id, name: name
  })
end

client.call
