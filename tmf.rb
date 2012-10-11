# Copyright (c) 2012 Mani Tadayon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# The Software shall be used for Good, not Evil.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module TMF
  class AssertionFailed < StandardError
    def initialize(a, b)
      super("Expected #{a} to equal #{b}")
    end
  end

  class ExpectationNotMet < StandardError
    def initialize(o, method)
      super("Expected #{o} to receive #{method}")
    end
  end

  def assert(a, opts)
    a == opts[:equals] ? true : raise( AssertionFailed.new(a,opts[:equals]) )
  end

  def stub(o, opts)
    old_method = o.respond_to?(opts[:method]) ? o.method(opts[:method]).to_proc : nil

    called = false
    o.singleton_class.send(:define_method, opts[:method]) { called = 1; opts[:return] }
    result = yield if block_given?

    raise ExpectationNotMet.new(o, opts[:method]) if opts[:spy] && !called

    result
  ensure
    old_method ?
      o.singleton_class.send(:define_method, opts[:method], old_method) :
      o.singleton_class.send(:undef_method, opts[:method])
  end
end