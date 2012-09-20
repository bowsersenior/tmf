module TMF
  class AssertionFailed < StandardError
    def initialize(a, b)
      msg = "Expected #{a} to equal #{b}"
      super(msg)
    end
  end

  def assert(a, b)
    raise AssertionFailed.new(a,b) unless a == b
  end

  # Usage:
  #   include TMF
  #
  #   class Foo
  #     def bar
  #       :bar
  #     end
  #   end
  #
  #   f = Foo.new
  #   f.bar
  #   # => :bar
  #
  #   stub(f, :bar, :baz){ puts f.bar }
  #   # => :baz
  #
  #   f.bar
  #   # => :bar
  #
  #   f.snafu
  #   # => NoMethodError: undefined method `snafu' for #<Foo:0x007fc3ea84c230>
  #
  #   stub(f, :snafu, :susfu){ puts f.snafu }
  #   # => susfu
  #
  #   f.snafu
  #   # => NoMethodError: undefined method `snafu' for #<Foo:0x007fc3ea84c230>
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

    yield if block_given?

    if restorer
      o.extend(restorer)
    else
      class << o
        self
      end.send :undef_method, message
    end

    nil
  end
end