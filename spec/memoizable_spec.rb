require 'spec_helper'

module ForgetMeNot

  class MemoizeTestClass
    include Memoizable
    include MethodCounter

    def method1
      record_call :method1
      'method1'
    end

    def method2(arg)
      record_call :method2
      "method2(#{arg})"
    end

    def method3(org, month, visit_type)
      record_call :method3
      "method3(#{org}, #{month}, #{visit_type})"
    end

    def method4(array_arg)
      record_call :method4
      "method4([#{array_arg.join ','}])"
    end

    def method5(hash_arg)
      record_call :method5
      "method5({#{hash_arg.map { |k, v| "#{k}/#{v}" }.join '|' }})"
    end

    memoize :method1
    memoize_with_args :method2, :method3, :method4, :method5
  end

  describe Memoizable do
    before do
      MemoizeTestClass.clear_calls
    end


    describe 'memoize arity-0 calls' do
      it 'should memoize calls from the same instance' do
        foo = MemoizeTestClass.new
        expect(foo.method1).to eq 'method1'
        expect(foo.method1).to eq 'method1'

        expect(MemoizeTestClass.count(:method1)).to eq 1
      end

      it 'should memoize calls from the different instances separately' do
        foo = MemoizeTestClass.new
        bar = MemoizeTestClass.new
        expect(foo.method1).to eq 'method1'
        expect(bar.method1).to eq 'method1'

        expect(MemoizeTestClass.count(:method1)).to eq 2
      end

      it 'should raise an error if called with a block on initial memoization' do
        foo = MemoizeTestClass.new
        expect do
          foo.method1 {'a block'}
        end.to raise_error 'Cannot pass blocks to memoized methods'
      end

      it 'should raise an error if called with a block after initial memoization' do
        foo = MemoizeTestClass.new
        foo.method1
        expect do
          foo.method1 {'a block'}
        end.to raise_error 'Cannot pass blocks to memoized methods'
      end
    end

    describe 'memoize arity > 0 calls' do
      it 'throws an exception if memoize is called for a function with arguments' do
        expect do
          Class.new do
            include Memoizable

            def method(arg)
            end
            memoize :method
          end
        end.to raise_error 'Cannot memoize with arity > 0.  Use memoize_with_args instead.'
      end

      it 'allows memoization if the allow_args option is true' do
        expect do
          Class.new do
            include Memoizable

            def method(arg)
            end
            memoize :method, allow_args: true
          end
        end.not_to raise_error
      end

      it 'allows memoization if memoize_with_args is called' do
        expect do
          Class.new do
            include Memoizable

            def method(arg)
            end
            memoize_with_args :method
          end
        end.not_to raise_error
      end


    end
    describe 'memoize arity-1 calls' do
      it 'should memoize calls from the same instance, same argument' do
        foo = MemoizeTestClass.new
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('foo')).to eq 'method2(foo)'

        expect(MemoizeTestClass.count(:method2)).to eq 1
      end

      it 'should memoize calls from the same instance, different arguments' do
        foo = MemoizeTestClass.new
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('bar')).to eq 'method2(bar)'
        expect(foo.method2('bar')).to eq 'method2(bar)'

        expect(MemoizeTestClass.count(:method2)).to eq 2
      end

      it 'should distinguish calls with null and blank arguments' do
        foo = MemoizeTestClass.new
        expect(foo.method2(nil)).to eq 'method2()'
        expect(foo.method2(nil)).to eq 'method2()'
        expect(foo.method2('')).to eq 'method2()'
        expect(foo.method2('')).to eq 'method2()'
        expect(foo.method2('bar')).to eq 'method2(bar)'
        expect(foo.method2('bar')).to eq 'method2(bar)'

        expect(MemoizeTestClass.count(:method2)).to eq 3
      end

      it 'should distinguish calls with different elements in an array argument' do
        foo = MemoizeTestClass.new
        expect(foo.method4([1, 2])).to eq 'method4([1,2])'
        expect(foo.method4([1, 2])).to eq 'method4([1,2])'
        expect(foo.method4([1, 3])).to eq 'method4([1,3])'
        expect(foo.method4([1, 3])).to eq 'method4([1,3])'
        expect(MemoizeTestClass.count(:method4)).to eq 2
      end

      it 'should distinguish calls with different elements in a hash argument' do
        foo = MemoizeTestClass.new
        expect(foo.method5(foo: 1, bar: 2)).to eq 'method5({foo/1|bar/2})'
        expect(foo.method5(foo: 1, bar: 2)).to eq 'method5({foo/1|bar/2})'

        expect(foo.method5(foo: 1, bar: 3)).to eq 'method5({foo/1|bar/3})'
        expect(foo.method5(foo: 1, bar: 3)).to eq 'method5({foo/1|bar/3})'

        expect(foo.method5(foo: 1, elvis: 2)).to eq 'method5({foo/1|elvis/2})'
        expect(foo.method5(foo: 1, elvis: 2)).to eq 'method5({foo/1|elvis/2})'

        expect(MemoizeTestClass.count(:method5)).to eq 3
      end

    end

    describe 'memoize arity-3 calls' do
      it 'should memoize calls from the same instance, different arguments' do
        foo = MemoizeTestClass.new
        expect(foo.method3('general', 201312, :emergency)).to eq 'method3(general, 201312, emergency)'
        expect(foo.method3('general', 201312, :emergency)).to eq 'method3(general, 201312, emergency)'
        expect(foo.method3('general', 201311, :emergency)).to eq 'method3(general, 201311, emergency)'
        expect(foo.method3('general', 201311, :emergency)).to eq 'method3(general, 201311, emergency)'

        expect(MemoizeTestClass.count(:method3)).to eq 2
      end
    end

  end
end
