# coding: utf-8

#require 'pp'
require 'progressbar'

require 'builder'
require 'json'

require 'net/http'


$LOAD_PATH.unshift File.dirname($0)+"/tools"
# from ./tools/
require 'extensions'
require 'bezier_curves'
require 'area_centroid'
require 'svg_territory_parsing'
require 'WarLightAPIClient'




settings = "config/production.yml"
abort "Settings file #{settings} not found!" if !File.exist? settings

require 'yaml'
settings = YAML::load_file(settings)

# check all required settings are there
["svgfile", "mapid", "email", "APIToken"].each {|key|
  abort "#{key} not found in settings!" if !settings.key?(key) or !settings[key]
}

abort "File #{settings["svgfile"]} not found!" if !File.exist? settings["svgfile"]


puts 'Working... this may take some time. Go have a cup of tea or something.'
$talktome = true

svg = WarLightSVG.new(settings["svgfile"])
territs = svg.all_polygons_as_points

centerpoints = {}

puts "Finding centerpoints..."
pbar = ProgressBar.new("Progress", territs.length)
territs.each_pair do |id, poly|
  centerpoints[id] = centroid poly
  pbar.inc
end
pbar.finish

puts ""
puts "Great, we've done it! Uploading data..."
puts ""

# add host and path to settings
settings[:host] = "warlight.net"
settings[:path] = '/API/SetMapDetails'
client = WarLightAPIClient.new(settings)

# add all commands into client
centerpoints.each_pair do |id, point|
  client.add_command({
    "command" => 'setTerritoryCenterPoint', id: id, x: point.x, y: point.y
  })
end
  
client.call
