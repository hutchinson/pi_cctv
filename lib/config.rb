# Simple configuration class

require 'json'

class Configuration

  def initialize(file)
    @file = file

    if File.exists?(@file)
      file_contents = File.read(@file)

      @config = JSON.parse(file_contents)
    else
      @config = Hash.new()
      puts "File '#{@file}' does not exist."
    end
  end

  def value(key, default=nil)
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

