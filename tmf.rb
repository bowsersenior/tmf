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