require 'json'
require 'net/http'

class WarLightAPIClient
  attr_accessor(:path, :host)
   
  def initialize(options = {})
    @request = {
      'email' => options["email"],
      'APIToken' => options["APIToken"],
      "mapID" => options["mapid"],
      :commands  =>  [
      ]
    }
    self.host = options[:host]
    self.path = options[:path]
  end

  def add_command cmd
    if !cmd.key? "command"
      raise ArgumentError("command needs key 'command'!")
    end
    
    # TODO more validation
    
    @request[:commands].push cmd
  end
  
  def clear_commands
    @request[:commands].clear
  end

  def call
    http = Net::HTTP.start(self.host, nil, nil, nil, nil, nil, {:use_ssl => true})
    req = @request.to_json

    response = http.post(self.path, req)

    if response.is_a?(Net::HTTPOK) && (response.body =~ /Success/)
      puts "It appears to have worked! Go check your map in the map designer now."
    else
      puts "Well damn, something didn't work. :( It might be a good idea to report the error along with the data below."
      puts response.body
    end

  end
  
end