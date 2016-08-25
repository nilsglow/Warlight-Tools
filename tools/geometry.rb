require 'savage'
require 'clipper'

module Geometry
  def area poly
    n=poly.length
    0.5 * (0...n).map{|i| poly[i].x * poly[(i+1)%n].y - poly[(i+1)%n].x * poly[i].y }.inject(&:+)
  end
  
  def centroid poly
    n=poly.length
    a=area poly
    
    x=1.0/(a*6) * (0...n).map{|i| (poly[i].x + poly[(i+1)%n].x) * (poly[i].x * poly[(i+1)%n].y - poly[(i+1)%n].x * poly[i].y) }.inject(&:+)
    y=1.0/(a*6) * (0...n).map{|i| (poly[i].y + poly[(i+1)%n].y) * (poly[i].x * poly[(i+1)%n].y - poly[(i+1)%n].x * poly[i].y) }.inject(&:+)
    
    Point[x, y]
  end
  
  def bezier_quadra p1, p2, p3, mu
    p = Point[0,0]
  
    mu2 = mu * mu;
    mum1 = 1 - mu;
    mum12 = mum1 * mum1;
    p.x = p1.x * mum12 + 2 * p2.x * mum1 * mu + p3.x * mu2;
    p.y = p1.y * mum12 + 2 * p2.y * mum1 * mu + p3.y * mu2;
    # p.z = p1.z * mum12 + 2 * p2.z * mum1 * mu + p3.z * mu2;
  
    return p
  end
  
  def bezier_cubic p1, p2, p3, p4, mu
    p = Point[0,0]
  
    mum1 = 1 - mu;
    mum13 = mum1 * mum1 * mum1;
    mu3 = mu * mu * mu;
  
    p.x = mum13*p1.x + 3*mu*mum1*mum1*p2.x + 3*mu*mu*mum1*p3.x + mu3*p4.x;
    p.y = mum13*p1.y + 3*mu*mum1*mum1*p2.y + 3*mu*mu*mum1*p3.y + mu3*p4.y;
    # p.z = mum13*p1.z + 3*mu*mum1*mum1*p2.z + 3*mu*mu*mum1*p3.z + mu3*p4.z;
  
    return p
  end
  
  def is_inside polygon, p
    n = polygon.length
    angle=0;
    p1 = Point[0,0]
    p2 = Point[0,0]
  
    polygon.each_index do |i|
      p1.x = polygon[i].x - p.x;
      p1.y = polygon[i].y - p.y;
      p2.x = polygon[(i+1)%n].x - p.x;
      p2.y = polygon[(i+1)%n].y - p.y;
      angle += __angle2d(p1.x,p1.y,p2.x,p2.y);
    end
  
    if ((angle).abs < Math::PI)
      return false
    else
      return true
    end
  end
  
  def __angle2d x1, y1, x2, y2
    theta1 = Math.atan2(y1,x1) rescue 0
    theta2 = Math.atan2(y2,x2) rescue 0
    dtheta = theta2 - theta1;
    while (dtheta > Math::PI)
      dtheta -= 2*Math::PI;
    end
    while (dtheta < -Math::PI)
      dtheta += 2*Math::PI;
    end
  
    return dtheta
  end

  def intersection a, b
    c = Clipper::Clipper.new
  
    c.add_subject_polygon a.map(&:to_a)
    c.add_clip_polygon b.map(&:to_a)
    c.intersection(:non_zero, :non_zero)[0].map{|pnt| Point.new(*pnt)}
  end

end

Point = Savage::Directions::Point
class Savage::Directions::Point
  def self.[] x, y
    Savage::Directions::Point.new(x, y)
  end
  def + other
    self.class.new(self.x + other.x, self.y + other.y)
  end
  
  def distance_sq other
    (self.x - other.x)**2  +  (self.y - other.y)**2
  end
  def distance other
    Math.sqrt self.distance_sq other
  end
end

def min *a; a.min; end
def max *a; a.max; end
