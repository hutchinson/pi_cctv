# Simple configuration class

require 'json'

class Configuration

  # Create new instance of the Configuration class
  def initialize(file)
    @file = file

    if File.exists?(@file)
      file_contents = File.read(@file)

      @config = JSON.parse(file_contents)
    else
      @config = Hash.new()
      puts "Warning: File '#{@file}' does not exist."
    end
  end

  # Return the value for the specified key, or the default
  # value if it has not been specified.
  def value(key, default = nil)
   if @config.has_key?(key)
     @config[key]
   else
     default
   end
  end

end

config = Configuration.new('etc/pi_cctv.json')

puts config.value("Frequency")
puts config.value("Quality", 100)

