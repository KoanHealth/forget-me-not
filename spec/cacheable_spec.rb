require 'spec_helper'

module ForgetMeNot
  module MethodCounter
    extend ActiveSupport::Concern
    module ClassMethods
      def clear_calls
        calls.clear
      end

      def calls
        @@calls ||= Hash.new(0)
      end

      def count(method_name)
        calls[method_name]
      end

      def record_call(method_name)
        calls[method_name] += 1
      end
    end

    def record_call(method_name)
      self.class.record_call(method_name)
    end
  end

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

  describe Cacheable do
    before do
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

    end
  end
end
