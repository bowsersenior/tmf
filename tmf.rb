module TMF
  class AssertionFailed < StandardError
    def initialize(a, b)
      msg = "Expected #{a} to equal #{b}"
      super(msg)
    end
  end

  def assert(a, b)
    if a == b
      true
    else
      raise AssertionFailed.new(a,b)
    end
  end

  def stub(o, message, return_value)
    stubber = Module.new do
      define_method message do
        return_value
      end
    end

    restorer = if o.respond_to?(message)
      old_method = o.method(message).to_proc
      Module.new do
        define_method message, old_method
      end
    end

    o.extend(stubber)

    result = yield if block_given?

    if restorer
      o.extend(restorer)
    else
      class << o
        self
      end.send :undef_method, message
    end

    result
  end
end