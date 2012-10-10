# TMF: a minimal testing tool for ruby

## Intro

RSpec is powerful and vast, but after using it extensively, I came to realize that really good tests only use a small sliver of its feature set. I looked at alternatives like Minitest and Bacon, but then I thought that all you need for testing are 2 methods and 2 methods only:

* assert
* stub

TMF is an attempt to provide a minimal but useful testing tool for ruby. It's not even a gem, just copy the code and you're done. It's about 20 LOC at the moment.

There are no tests for TMF itself. My goal is for it to be as simple as possible. Using another testing tool to test TMF seems wrong, and using it to test itself is also not right.

I hope to use TMF in my projects to refine it and see if it is practical to do testing with such a minimalistic tool.

## Usage:

```ruby

    include TMF

    assert(1 + 1, 2)
    # => true

    assert(1 + 1, 3)
    # => TMF::AssertionFailed: Expected 2 to equal 3

    assert(Object.foo, :bar)
    # => NoMethodError: undefined method `foo' for Object:Class

    stub( Object, :foo) do
      # within this block, Object.foo returns nil
      assert(Object.foo, nil)
    end
    # => true

    stub( Object, :foo, :bar) do
      # within this block, Object.foo returns :bar
      assert(Object.foo, :bar)
    end
    # => true

    # Object.foo is no longer defined
    Object.foo
    # => NoMethodError: undefined method `foo' for Object:Class

    Object.methods.grep /foo/
    # => []

    stub(Object, :foo, :bar){ Object.methods.grep /foo/ }
    # => [:foo]

    Object.methods.grep /foo/
    # => []

    # stub can also override existing methods
    Object.to_s
    # => "Object"

    stub(Object, :to_s, :cheezburger) do
      Object.to_s
    end
    # => :cheezburger

    # outside the stub block to_s is back to normal
    Object.to_s
    # => "Object"
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

    class Foo; end

    f = Foo.new

    # passing test
    assert(Foo, f.class)
    # => true

    # failing test
    assert('Bar', f.class)
    # => TMF::AssertionFailed: Expected Bar to equal Foo

    # stub with passing test
    stub(f, :class, 'Bar') do
      assert('Bar', f.class)
    end
    # => true

    # stub with failing test
    stub(f, :bar, :baz) do
      assert(f.bar, :snafu)
    end
    # TMF::AssertionFailed: Expected baz to equal snafu

    # testing a raised error
    begin
      f.nothingthere
    rescue NoMethodError
      assert(
        $!.message.include?("undefined method `nothingthere'"),
        true
      )
    end
    # => true

    # Multiple stubs via nesting
    stub(Object, :foo, :bar) do
      stub(Object, :sna, :fu) do
        assert(
          [Object.foo, Object.sna],
          [:bar, :fu]
        )
      end
    end
    # => true

    # Override previous stubs
    stub(Object, :foo, :bar) do
      assert(Object.foo, :bar)

      stub(Object, :foo, :baz) do
        assert(Object.foo, :baz)

        stub(Object, :foo, :snafu) do
          assert(Object.foo, :snafu)
        end
      end
    end
    # => true

    # Chained stubs
    # e.g. Object.foo.bar
    stub(Object, :foo) do
      stub( Object.foo, :bar, :baz ) do
        Object.foo.bar
      end
    end
    # => :baz
```

Then, you can run the tests above with:

```shell

    $ ruby test/foo_test.rb && echo "all tests pass"
    # => all tests pass
```