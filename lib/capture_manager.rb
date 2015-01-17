# The capture manager is responsible for scheduling the capture of an
# image as per the user's settings and executing the various pre-and
# post capture handlers and storage handler.
#

require 'singleton'

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

  # The CaptureManager is responsible for scheduling images to be taken on the
  # given schedule and calling the registered CaptureHandlers and
  # StorageHandlers.
  class CaptureManager
    include Singleton

    def initialize()
      @active_storage_handler = nil
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
  end
end

class TestStorageHandler < PiCctv::StorageHandler

  def store(image_path, context)
    puts(image_path, context)
  end

  # Should return name of the active storage handler.
  def name()
    "TestStorageHandler"
  end
end

PiCctv::CaptureManager.instance.set_active_storage_handler TestStorageHandler.new
PiCctv::CaptureManager.instance.set_active_storage_handler TestStorageHandler.new
