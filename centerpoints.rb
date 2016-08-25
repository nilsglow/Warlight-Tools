# coding: utf-8

require 'pp'
require 'progressbar'

require 'savage'

require 'nokogiri'
require 'builder'
require 'json'

require 'net/http'


$LOAD_PATH.unshift File.dirname($0)+"/tools"
# from ./tools/
require 'extensions'
require 'bezier_curves'
require 'area_centroid'
require 'svg_territory_parsing'




exit if defined? Ocra
################################################################
# script starts here
################################################################


infile = "/home/nils/work/spielentwicklung/WarLight/Wien_klein/QGIS_export2.svg"
#infile = "test.svg"


while !File.exist? infile
  puts 'No such file!'
  exit
end

mapid = 59396
email = ''
APIToken = ''

puts 'Working... this may take some time. Go have a cup of tea or something.'
$talktome = true

svg = File.read infile
territs = all_territs_in_svg svg

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

# FIXME needs updating to JSON API
#
req = {
  'email' => email,
  'APIToken' => APIToken,
  "mapID" => mapid,
  "commands"  =>  [
  ]
}

centerpoints.each_pair do |id, point|
  req["commands"].push({
    "command" => 'setTerritoryCenterPoint', id: id, x: point.x, y: point.y
  })
end
  
json = req.to_json

api = 'https://warlight.net'

http = Net::HTTP.start('warlight.net')
response = http.post('/API/SetMapDetails', json)

# FIXME parse JSON and check Success property
if response.is_a?(Net::HTTPOK) && (response.body =~ /Success/)
  puts "It appears to have worked! Go check your map in the map designer now."
else
  puts "Well damn, something didn't work. :( It might be a good idea to report the error along with the data below."
  puts response.body
end
