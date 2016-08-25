require 'optparse'


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{ARGV[0]} [options]"

  opts.on('-s', '--svg FILE', 'Filename (with path) of the SVG to process') { |v| options[:svg] = v }
  opts.on('-m', '--mapid ID', 'ID of the WarLight map to work with') { |v| options[:mapid] = v }

end.parse!




puts options
