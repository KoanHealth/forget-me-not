require 'spec_helper'

module ForgetMeNot
  class TestClass
    include Cacheable
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

    def self.cache_warm(*args)
      item = new
      item.method1
      item.method2(args.first)
    end

    cache_results :method1, :method2, :method3, :method4, :method5
  end


  class TestClass2
    include Cacheable
    include MethodCounter

    attr_reader :org, :month

    def initialize(org, month)
      @org = org
      @month = month
    end

    def method1
      record_call :method1
      "[#{org},#{month}].method1"
    end

    cache_results :method1, include: [:org, :month]
  end

  class TestClass3 < TestClass2

  end

  class TestClassException1
    include Cacheable


    class << self
      attr_accessor :cache_warm_called
      def cache_warm(*args)
        self.cache_warm_called = true
        raise "We're not going to take it"
      end
    end
  end

  class TestClassException2
    include Cacheable

    class << self
      attr_accessor :cache_warm_called

      def cache_warm(*args)
        self.cache_warm_called = true
        raise "We're not going to take it"
      end
    end

  end


  describe Cacheable do
    before do
      Cacheable.log_cache_activity = true
      Cacheable.cache = ActiveSupport::Cache::MemoryStore.new
      TestClass.clear_calls
      TestClass2.clear_calls
    end


    describe 'cache arity-0 calls' do
      it 'should cache calls from the same instance' do
        foo = TestClass.new
        expect(foo.method1).to eq 'method1'
        expect(foo.method1).to eq 'method1'

        expect(TestClass.count(:method1)).to eq 1
      end

      it 'should cache calls from the different instances' do
        foo = TestClass.new
        bar = TestClass.new
        expect(foo.method1).to eq 'method1'
        expect(bar.method1).to eq 'method1'

        expect(TestClass.count(:method1)).to eq 1
      end

      it 'cache should expire' do
        foo = TestClass.new
        expect(foo.method1).to eq 'method1'

        Timecop.freeze(DateTime.now + 13.hours) do
          expect(foo.method1).to eq 'method1'
        end

        expect(TestClass.count(:method1)).to eq 2
      end

      it 'should raise an error if called with a block on initial caching' do
        foo = TestClass.new
        expect do
          foo.method1 { 'a block' }
        end.to raise_error 'Cannot pass blocks to cached methods'
      end

      it 'should raise an error if called with a block after initial caching' do
        foo = TestClass.new
        foo.method1
        expect do
          foo.method1 { 'a block' }
        end.to raise_error 'Cannot pass blocks to cached methods'
      end

    end

    describe 'cache arity-1 calls' do
      it 'should cache calls from the same instance, same argument' do
        foo = TestClass.new
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('foo')).to eq 'method2(foo)'

        expect(TestClass.count(:method2)).to eq 1
      end

      it 'should cache calls from the same instance, different arguments' do
        foo = TestClass.new
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('foo')).to eq 'method2(foo)'
        expect(foo.method2('bar')).to eq 'method2(bar)'
        expect(foo.method2('bar')).to eq 'method2(bar)'

        expect(TestClass.count(:method2)).to eq 2
      end

      it 'should distinguish calls with null and blank arguments' do
        foo = TestClass.new
        expect(foo.method2(nil)).to eq 'method2()'
        expect(foo.method2(nil)).to eq 'method2()'
        expect(foo.method2('')).to eq 'method2()'
        expect(foo.method2('')).to eq 'method2()'
        expect(foo.method2('bar')).to eq 'method2(bar)'
        expect(foo.method2('bar')).to eq 'method2(bar)'

        expect(TestClass.count(:method2)).to eq 3
      end

      it 'should distinguish calls with different elements in an array argument' do
        foo = TestClass.new
        expect(foo.method4([1, 2])).to eq 'method4([1,2])'
        expect(foo.method4([1, 2])).to eq 'method4([1,2])'
        expect(foo.method4([1, 3])).to eq 'method4([1,3])'
        expect(foo.method4([1, 3])).to eq 'method4([1,3])'
        expect(TestClass.count(:method4)).to eq 2
      end

      it 'should distinguish calls with different elements in a hash argument' do
        foo = TestClass.new
        expect(foo.method5(foo: 1, bar: 2)).to eq 'method5({foo/1|bar/2})'
        expect(foo.method5(foo: 1, bar: 2)).to eq 'method5({foo/1|bar/2})'

        expect(foo.method5(foo: 1, bar: 3)).to eq 'method5({foo/1|bar/3})'
        expect(foo.method5(foo: 1, bar: 3)).to eq 'method5({foo/1|bar/3})'

        expect(foo.method5(foo: 1, elvis: 2)).to eq 'method5({foo/1|elvis/2})'
        expect(foo.method5(foo: 1, elvis: 2)).to eq 'method5({foo/1|elvis/2})'

        expect(TestClass.count(:method5)).to eq 3
      end

    end

    describe 'cache arity-3 calls' do
      it 'should cache calls from the same instance, different arguments' do
        foo = TestClass.new
        expect(foo.method3('general', 201312, :emergency)).to eq 'method3(general, 201312, emergency)'
        expect(foo.method3('general', 201312, :emergency)).to eq 'method3(general, 201312, emergency)'
        expect(foo.method3('general', 201311, :emergency)).to eq 'method3(general, 201311, emergency)'
        expect(foo.method3('general', 201311, :emergency)).to eq 'method3(general, 201311, emergency)'

        expect(TestClass.count(:method3)).to eq 2
      end
    end

    describe 'cache with instance args' do
      it 'same instance parameters' do
        foo = TestClass2.new('general', 201312)
        bar = TestClass2.new('general', 201312)
        expect(foo.method1).to eq '[general,201312].method1'
        expect(bar.method1).to eq '[general,201312].method1'
        expect(TestClass2.count(:method1)).to eq 1
      end

      it 'different instance parameters' do
        foo = TestClass2.new('general', 201312)
        bar = TestClass2.new('general', 201311)
        expect(foo.method1).to eq '[general,201312].method1'
        expect(bar.method1).to eq '[general,201311].method1'
        expect(TestClass2.count(:method1)).to eq 2
      end

      it 'Retains key consistency across process runs' do
        foo = TestClass2.new('general', 201312)
        foo.method1

        ugly_hash_key = '90914de582dd73182e909216e27b3898120e07c3'
        expect(Cacheable.cache.read(ugly_hash_key)).not_to be_nil
      end
    end

    describe 'cachers' do

      it 'should track objects that include Cacheable' do
        expected = [TestClass, TestClass2].to_set
        expect(Cacheable.cachers & expected).to eq expected
      end

      it 'cachers_and_descendants should include descendants' do
        expected = [TestClass, TestClass2, TestClass3].to_set
        expect(Cacheable.cachers_and_descendants & expected).to eq expected
      end

      it 'Cache Warming should call warmed methods' do
        Cacheable.warm('foo')

        expect(TestClass.count(:method1)).to eq 1
        expect(TestClass.count(:method2)).to eq 1
        expect(TestClass.count(:method3)).to eq 0
        expect(TestClass.count(:method4)).to eq 0
        expect(TestClass.count(:method5)).to eq 0
      end

      it 'Cache Warming should call warm methods again' do
        TestClass.new.method1
        TestClass.new.method2('foo')

        expect(TestClass.count(:method1)).to eq 1
        expect(TestClass.count(:method2)).to eq 1

        Cacheable.warm('foo')

        expect(TestClass.count(:method1)).to eq 2
        expect(TestClass.count(:method2)).to eq 2
        expect(TestClass.count(:method3)).to eq 0
        expect(TestClass.count(:method4)).to eq 0
        expect(TestClass.count(:method5)).to eq 0
      end

      it 'Cache warming should keep going when encountering exceptions' do
        TestClassException1.cache_warm_called = false
        TestClassException2.cache_warm_called = false

        Cacheable.warm('foo')

        expect(TestClassException1.cache_warm_called).to be_true
        expect(TestClassException2.cache_warm_called).to be_true
      end
    end
  end
end
