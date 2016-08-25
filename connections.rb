# coding: utf-8

require 'progressbar'


$LOAD_PATH.unshift File.dirname($0)+"/tools"
# from ./tools/
require 'warlight'



include WarLight
settings = WarLight::load_settings



puts 'Working... this may take some time. Go have a cup of tea or something.'
$talktome = true

svg = WarLightSVG.new(settings["svgfile"])
territs = svg.all_polygons_as_points

class Array
  attr_accessor :_bbox_cache
  attr_accessor :_bbox_cache_hash
  
  def bounding_box
    if self.hash == @_bbox_cache_hash
      @_bbox_cache
    else
      left, right = *self.map{|p| p.x}.minmax
      top, bottom = *self.map{|p| p.y}.minmax
      
      @_bbox_cache_hash = self.hash
      @_bbox_cache = [ Point[left, top],  Point[right, bottom] ]
    end
  end
  
  def bbox_intersect? other
    bb1 = self.bounding_box
    bb2 = other.bounding_box
    
    return (
      (
        bb2.map(&:x).any?{|x| x.between? *bb1.map(&:x) } or
        bb1.map(&:x).any?{|x| x.between? *bb2.map(&:x) }
      )\
      and
      (
        bb2.map(&:y).any?{|y| y.between? *bb1.map(&:y) } or
        bb1.map(&:y).any?{|y| y.between? *bb2.map(&:y) }
      )
    )
  end
  def bbox_close? other, dist=5
    a = other.bounding_box
    # enlarge the other bbox by dist
    a[0].x -= dist
    a[0].y -= dist
    a[1].x += dist
    a[1].y += dist
    
    self.bbox_intersect? a
  end
end


# ary.combination(2).

n = territs.length
count = n*(n-1)/2
puts "Finding connections... (checking #{count} pairs)"
pbar = ProgressBar.new("Progress", count)

connections = []

territs.to_a.combination(2).each do |(id1, poly1), (id2, poly2)|
  if poly1.bbox_close? poly2
    conn = poly1.product(poly2).any?{|p1, p2| p1.distance_sq(p2) < 25 }
    if conn
      connections << [id1, id2]
    end
  end
  
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
connections.each do |id1, id2|
  client.add_command({
    "command" => 'addTerritoryConnection', id1: id1, id2: id2, wrap: 'Normal'
  })
end

client.call
