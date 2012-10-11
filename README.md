# TMF: a minimal testing tool for ruby

## Intro

[RSpec][1] is powerful and vast, but after using it extensively, I came to realize that really good tests only use a small sliver of its feature set. I looked at alternatives like [minitest][2] and [Bacon][3], but then I had an interesting thought: you could write awesome tests using just 2 methods:

* assert
* stub

TMF is an attempt to provide a minimal but useful testing tool for ruby. It's not even a gem, just copy the code and you're done. It's about 30 LOC at the moment.

There are no automated tests for TMF itself. My goal is to keep it as simple as possible. Using another testing tool to test TMF seems wrong, and using TMF to test itself is also not right. I do rigorously test TMF by hand using the examples in the README. The code is meant to be simple enough so that its correctness can be verified by hand.

I will use TMF in my projects and discover if such a minimalistic tool can be practical. Along the way, I will refine its features and look forward to hearing what you think about TMF!

## Usage:

```ruby

    include TMF

    assert(1 + 1, :equals => 2)
    # => true

    assert(1 + 1, :equals => 3)
    # => TMF::ExpectationNotMet: Expected 2 to equal 3

    assert(Object.foo, :equals => :bar)
    # => NoMethodError: undefined method `foo' for Object:Class

    stub(Object, :method => :foo) do
      # within this block, Object.foo returns nil
      assert Object.foo, :equals => nil
    end
    # => true

    stub(Object, :method => :foo, :return => :bar) do
      # within this block, Object.foo returns :bar
      assert(Object.foo, :equals => :bar)
    end
    # => true

    # Object.foo is no longer defined
    Object.foo
    # => NoMethodError: undefined method `foo' for Object:Class

    Object.methods.grep /foo/
    # => []

    stub(Object, :method => :foo){ Object.methods.grep /foo/ }
    # => [:foo]

    Object.methods.grep /foo/
    # => []

    # stub can also override existing methods
    Object.to_s
    # => "Object"

    stub(Object, :method => :to_s, :return => :cheezburger) do
      Object.to_s
    end
    # => :cheezburger

    # outside the stub block, Object.to_s is back to normal
    Object.to_s
    # => "Object"

    # set a spy to check if the stub was called
    stub(Object, :method => :foo, :spy => true) do
      'y u no call ?'
    end
    # => TMF::ExpectationNotMet: Expected Object to receive foo

    stub(Object, :method => :foo, :spy => true) do
      Object.foo
    end
    # => nil
```

## A more detailed example

Let's say you have a file `PROJECT_ROOT/lib/foo.rb` with the following:

```ruby

    class Foo
      def bar
        :bar
      end
    end
```

And you also have a file `PROJECT_ROOT/test/foo_test.rb` with the following:

```ruby

    require_relative '../lib/foo.rb'
    require_relative './tmf.rb'

    include TMF

    f = Foo.new

    # passing test
    assert(f.class, :equals => Foo)
    # => true

    # failing test
    assert(f.class, :equals => 'Bar')
    # => TMF::ExpectationNotMet: Expected Foo to equal Bar

    # stub with passing test
    stub(f, :method => :class, :return => 'Bar') do
      assert(f.class, :equals => 'Bar')
    end
    # => true

    # stub with failing test
    stub(f, :method => :bar, :return => :baz) do
      assert(f.bar, :equals => :snafu)
    end
    # TMF::ExpectationNotMet: Expected baz to equal snafu

    # testing a raised error
    begin
      f.nothingthere
    rescue NoMethodError
      assert(
        $!.message.include?("undefined method `nothingthere'"),
        :equals => true
      )
    end
    # => true

    # stub with spy and return value
    stub(f, :method => :bar, :return => :baz, :spy => true) do
      'all your base are belong to us'
    end
    # => TMF::ExpectationNotMet: Expected #<Foo:0x007f85331b4ee0> to receive bar

    # stub with spy and return value
    stub(f, :method => :bar, :return => :baz, :spy => true) do
      assert(f.bar, :equals => :baz)
    end
    # => true

    # Multiple stubs via nesting
    stub(f, :method => :foo, :return => :bar) do
      stub(f, :method => :sna, :return => :fu) do
        assert(
          [f.foo, f.sna],
          :equals => [:bar, :fu]
        )
      end
    end
    # => true

    # Override previous stubs
    stub(f, :method => :foo, :return => :bar) do
      assert(f.foo, :equals => :bar)

      stub(f, :method => :foo, :return => :baz) do
        assert(f.foo, :equals => :baz)

        stub(f, :method => :foo, :return => :snafu) do
          assert(f.foo, :equals => :snafu)
        end
      end
    end
    # => true

    # Chained stubs
    # e.g. f.foo.bar
    stub(f, :method => :foo) do
      stub( f.foo, :method => :bar, :return => :baz ) do
        assert(f.foo.bar, :equals => :baz)
      end
    end
    # => true
```

Then, you can run the tests above with:

```shell

    $ ruby test/foo_test.rb && echo "all tests pass"
    # => all tests pass
```

[1]: https://www.relishapp.com/rspec
[2]: http://docs.seattlerb.org/minitest/
[3]: https://github.com/chneukirchen/bacon