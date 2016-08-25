#coding: utf-8

require 'progressbar'
require 'savage'
require 'nokogiri'
require 'matrix'

$parse_infos = []

class Hash
  def hmap(&block)
    Hash[self.map {|k, v| block.call(k,v) }]
  end
end

class WarLightSVG
  def initialize(svgfile)
    svg = File.read svgfile
    @noko = Nokogiri.XML svg    
  end
  
  def territory_as_points node
  	case node.name
  	when 'path'
  		points = self.parse_path_to_poly node['d']
  		
  	when 'polygon'
  		points = self.parse_path_to_poly "M #{node['points']} z"
  		
  	when 'rect'
  		left = node['x'].to_f
  		right = left + node['width'].to_f
  		top = node['y'].to_f
  		bottom = top + node['height'].to_f
  		
  		points = [ Point[left,top], Point[right,top], Point[right,bottom], Point[left,bottom] ]
  		
  	when 'circle'
  		# we don't have to represent it accurately
  		cx, cy, r = node['cx'].to_f, node['cy'].to_f, node['r'].to_f
  		rx = ry = r
  		
  		points = [ Point[cx,cy-ry], Point[cx+rx,cy], Point[cx,cy+ry], Point[cx-rx,cy] ]
  	
  	when 'ellipse'
  		cx, cy, rx, ry = node['cx'].to_f, node['cy'].to_f, node['rx'].to_f, node['ry'].to_f
  		
  		points = [ Point[cx,cy-ry], Point[cx+rx,cy], Point[cx,cy+ry], Point[cx-rx,cy] ]
  		
  	else
  		$parse_infos.push "unrecognized element #{node.name}[id=#{node['id']}]; skipping"
  	end
  	
  	transforms = []
  	cur = node
  	while cur and cur.respond_to? :parent
  		transforms.push cur['transform']
  		cur = cur.parent
  	end
  	
  	transforms = transforms.compact.join ' '
  	operations = transforms.scan(/(\w+)\(([^\(\)]+)\)/)
  	operations.each do |op, arg|
  		case op
  		when 'translate'
  			xm, ym = *arg.strip.split(/[, ]+/).map{|a| a.to_f}
  			d = Point[xm, ym]
  			
  			points.map!{|p| p + d}
  		when 'matrix'
  			a, b, c, d, e, f = *arg.strip.split(/[, ]+/).map{|a| a.to_f}
  			matrix = Matrix[
  				[a, c, e],
  				[b, d, f],
  				[0, 0, 1]
  			]
  
  			points.map!{|p|
  				 m = Matrix[
  					 [p.x],
  					 [p.y],
  					 [1]
  				 ]
  				 m = matrix * m
  				 Point[m.element(0,0), m.element(1,0)]
  			}
  		else
  			$parse_infos.push "unrecognized transform #{op} for #{node['id']}; skipping"
  		end
  	end
  	
  	return points
  end
  
  def parse_path_to_poly pathdata
  	path = Savage::Parser.parse pathdata
  	path = path.subpaths[0].directions
  
  	last_point = Point[0,0]
  	poly = path.map do |command|
  		case command
  		when Savage::Directions::MoveTo # this will give wrong values for multipart territories.
  			last_point = (command.absolute? ? Point[0,0] : last_point) + command.target
  			[last_point]
  			
  		when Savage::Directions::LineTo
  			last_point = (command.absolute? ? Point[0,0] : last_point) + command.target
  			[last_point]
  			
  		when Savage::Directions::VerticalTo
  			actual_target = Point[(command.absolute? ? last_point.x : 0), command.target]
  			last_point = (command.absolute? ? Point[0,0] : last_point) + actual_target
  			[last_point]
  			
  		when Savage::Directions::HorizontalTo
  			actual_target = Point[command.target, (command.absolute? ? last_point.y : 0)]
  			last_point = (command.absolute? ? Point[0,0] : last_point) + actual_target
  			[last_point]
  			
  		when Savage::Directions::CubicCurveTo
  			points = []
  			
  			len = last_point.distance command.target
  			# obliczamy najwyzej 10 punktow po drodze, mniej dla sciezek < 50 px - dla 5px i mniejszych 0
  			step = max( min(1, 5/len), 0.1 )
  			
  			(0.0..1.0).step(step).map do |mu|
  				points << bezier_cubic(
  					last_point, 
  					(command.absolute? ? Point[0,0] : last_point) + command.control_1, 
  					(command.absolute? ? Point[0,0] : last_point) + command.control_2, 
  					(command.absolute? ? Point[0,0] : last_point) + command.target, 
  					mu
  				)
  			end
  			last_point = points.last
  			points
  			
  		when Savage::Directions::ClosePath
  			[]
  		else
  			p command
  			raise "unsupported command #{command.class}"
  		end
  	end
  	poly = poly.inject :+ # poly was an array of arrays of points
  	
  	return poly
  end
  
  def territory_names
    territs = @noko.css('[id^=Territory_]')
    # our hmap method expects the block to return an array. its elements become key and value...
    names = {}
    territs.map{|node| names[node['id'][/\d+/]] = node["inkscape:label"] }
    names
  end
  
  def all_polygons_as_points
  	
  	territs = @noko.css('[id^=Territory_]')
  	puts "This map appears to have #{territs.length} territories." if $talktome
  	
  	ids = territs.map{|t| t['id'][/\d+/] }
  	
  	puts "Parsing polygons..." if $talktome
  	pbar = ProgressBar.new("Progress", territs.length)
  	polys = territs.map{|t| pbar.inc; self.territory_as_points t }
  	pbar.finish
  	
  	puts $parse_infos.join("\n") if $talktome
  	
  	Hash[ ids.zip(polys) ]
  end
end
