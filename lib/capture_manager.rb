# The capture manager is responsible for scheduling the capture of an
# image as per the user's settings and executing the various pre-and
# post capture handlers and storage handler.
#

require 'singleton'
require 'timers'

require_relative 'config'

module PiCctv
  # Capture handlers can be executed either before the active storage handler
  # is run (in which case they can modify the image being stored), or post
  # the active storage handler in which case the image will have been stored
  # but it could do something like analyse the image for movement.
  class CaptureHandler
    # Process the specified image, the context provides a Hash of
    # information about when the image was taken and what settings
    # were used to take it.
    def process(image_path, context)
      # Do nothing, this is just a base class
    end

    def name()

    end
  end

  # StorageHandlers abstract the means of storing the image, the CaptureManager
  # has only one active StorageHandler at any one time.
  # For example there may be a LocalDiskStorageHandler or a
  # DropboxStorageHandler
  class StorageHandler

    # Store the specified image, similar to the CaptureHandler the context
    # provides information about how the image was taken and how it should
    # be stored.
    def store(image_path, context)

    end

    # Should return name of the active storage handler.
    def name()

    end
  end

  PRE_STORAGE = :PRE_STORAGE
  POST_STORAGE = :POST_STORAGE

  # The CaptureManager is responsible for scheduling images to be taken on the
  # given schedule and calling the registered CaptureHandlers and
  # StorageHandlers.
  class CaptureManager
    include Singleton

    def initialize()
      @active_storage_handler = nil
      @capture_handlers = {}

      @capture_handlers[PRE_STORAGE] = []
      @capture_handlers[POST_STORAGE] = []

      @config = nil

      @timer_group = Timers::Group.new
    end

    # Start up the capture manager using the specified configuration file
    def boot(config_file = 'etc/pi_cctv.json')
      @config = PiCctv::Configuration.new(config_file)


      # Build the context that will be passed to our plugins.
      @context = {}

      frequency = @config.value("Frequency", 1).to_i
      frequency = 1 / frequency
      @context[:frequency] = frequency

      width = @config.value("ImageWidth", 1024).to_i
      @context[:width] = width

      height = @config.value("ImageHeight", 1024).to_i
      @context[:height] = height

      puts "Booted up with #{@config}."

      # Start taking surveillance!
      @timer_group.every(frequency) { PiCctv::CaptureManager.instance.timer_handler }
      loop { @timer_group.wait }
    end

    def timer_handler()
      # Take picture here.
      current_time = Time.new
      image_file_path = 'foo'

      # Update the context
      @context[:capture_time] = current_time

      # Next, iterate over the pre-storage handlers.
      @capture_handlers[PRE_STORAGE].each do | plugin |
        begin
          plugin.process(image_file_path, @context)
        rescue standarderror => error
          puts "Error: '#{error}' while executing pre-storage handler '#{plugin.name}'."
        end
      end

      # Next, store the image
      begin
        @active_storage_handler.store(image_file_path, @context)
      rescue StandardError => error
        puts "Error: '#{error}' while executing storage handler '#{@active_storage_handler.name}'."
      end

      # Finally, run the post-storage handlers.
      @capture_handlers[POST_STORAGE].each do | plugin |
        begin
          plugin.process(image_file_path, @context)
        rescue standarderror => error
          puts "Error: '#{error}' while executing post-storage handler '#{plugin.name}'."
        end
      end
    end

    # Set the active storage handler
    #
    # TODO: Look into passing the Class rather than a instance, then we
    # can create instances of the storage handler on demand.
    def set_active_storage_handler(new_handler)
      if new_handler == nil or not new_handler.kind_of? StorageHandler
        puts "Warning: Storage handler must not be nil and must derive from StorageHandler."
        return
      end

      if @active_storage_handler != nil
        puts "Replacing '#{@active_storage_handler.name}' with '#{new_handler.name}'"
      end

      @active_storage_handler = new_handler
    end

    # Register a capture handler to run either pre or post the storage handler
    def register_capture_handler(handler, execute_when = POST_STORAGE)
      if handler == nil or not handler.kind_of? CaptureHandler
        puts "Warning: handler must not be nil and must derive from CaptureHandler."
      end

      if !(execute_when == PRE_STORAGE or execute_when == POST_STORAGE)
        puts "Warning: execute_when must be either PRE_STORAGE or POST_STORAGE."
        return
      end

      @capture_handlers[execute_when].push(handler)
    end
  end
end

###############################################################################

class TestStorageHandler < PiCctv::StorageHandler
  def store(image_path, context)
    puts "#{image_path}, #{context}"
  end

  # Should return name of the active storage handler.
  def name()
    "TestStorageHandler"
  end
end

###############################################################################

class TestCaptureHandler < PiCctv::CaptureHandler
  def process(image, context)
    puts "#{image}, #{context}"
  end

  def name()
    "TestCaptureHandler"
  end
end

captureManager = PiCctv::CaptureManager.instance
captureManager.set_active_storage_handler TestStorageHandler.new
captureManager.set_active_storage_handler TestStorageHandler.new

captureManager.register_capture_handler(TestCaptureHandler.new)
captureManager.register_capture_handler(TestCaptureHandler.new, PiCctv::PRE_STORAGE)

captureManager.boot

