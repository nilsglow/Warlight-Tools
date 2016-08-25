# coding: utf-8

require 'progressbar'
require 'yaml'

$LOAD_PATH.unshift File.dirname($0)+"/tools"
# from ./tools/
require 'warlight'



include WarLight
settings = WarLight::load_settings


puts 'Working... this may take some time. Go have a cup of tea or something.'
$talktome = true

svg = WarLightSVG.new(settings["svgfile"])
territs = svg.all_polygons_as_points

centerpoints = {}

puts "Finding centerpoints..."

# load geometry namespace
include Geometry

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
