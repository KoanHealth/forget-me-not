# ForgetMeNot
[![Build Status](https://secure.travis-ci.org/KoanHealth/forget-me-not.png?branch=master&.png)](http://travis-ci.org/KoanHealth/forget-me-not)
[![Code Climate](https://codeclimate.com/github/KoanHealth/forget-me-not.png)](https://codeclimate.com/github/KoanHealth/forget-me-not)
[![Coverage Status](https://coveralls.io/repos/KoanHealth/forget-me-not/badge.png?branch=master)](https://coveralls.io/r/KoanHealth/forget-me-not)

Provides memoization and caching mixins

## Installation

Add this line to your application's Gemfile:

    gem 'forget-me-not'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install forget-me-not

## Background 

Although the code is quite similar between the two mixins they solve very different problems.

### Memoization
Memoization is intended to allow a single object instance to remember the result of a method call.  If you have
ever written something like:

    def full_name
      @full_name ||= "#{last_name}, #{first_name}"
	end

then you have done memoization.  The result is calculated the first time full_name is called.  Subsequent calls return
the same value and do not incur the overhead of calculating the result.  Trivial in this case, but the work could be quite
substantial.

Memoization is scoped to an object.  If you ask two different User instances what the memoized full_name is, then
you will get a different answer from each of them.

### Caching

Caching is similar, but broader in scope.  For us, the initial use case was a dashboard in one of our products that
aggregated the numerical values of several hundred thousand medical claims.  Rather than performing this query every
time we generated the dashboard, we cached the results of the query allowing us to display the web page in a snap.

Our caching mixin is intended to be used with a cache like memcached that is available across your servers.  It includes
convenience methods to allow cache warming.

Caching is system wide.  If the same cached method for two separate instances is called, the actual method should only be
called once.

## Usage

### Memoizable Mixin
    class MyClass
      include ForgetMeNot::Memoizable

      def some_method
        'result'
      end

      def some_other_method(with_an_arg)
      	"result2-#{with_an_arg}"
      end

      memoize :some_method, :some_other_method
    end

Calls to both some_method and some_other_method are memoized.  Notice that some_other_method takes an argument, differing
argument values will result in different results being memoized.

By default, the memoization code stores results in a simple Hash based cache.  If you have other requirements, perhaps
a thread-safe storage, then set the ForgetMeNot::Memoization.storage_builder property to a proc that will create a new
instance of whatever storage you desire.

### Cacheable Mixin
The basics are unsurprising:

    class MyClass
      include ForgetMeNot::Cacheable

      def some_method
        'result'
      end

      cache :some_method
    end

Like memoization, arguments are fully supported and will result in distinct storage to the cache.

To control warming the cache, implement the cache_warm method

    class MyClass
      include ForgetMeNot::Cacheable

      def some_method
        'result'
      end

      cache :some_method

      # Warm the cache for this object
      def self.cache_warm(*args)
      	instance = new
      	instance.some_method
      end
    end

Then somewhere (a rake task perhaps), call Cacheable.warm.  Whatever args you pass to warm are passed to every class that
included Cacheable.

In addition to the arguments passed to the cached method, Cacheable allows instance properties to also be used as cache
key members.

    class MyClass
      include ForgetMeNot::Cacheable

      attr_reader :important_property
      def initialize(important_property)
      	@important_property = important_property
      end

      def some_method
        'result'
      end

      cache :some_method, :include => :important_property
    end

By default, the cache will attempt to use the Rails cache.  If that isn't found, but ActiveSupport is available, a new
instance of MemoryStore will be used.  Failing that, cache will raise an error.  This is intended to provide a reasonably
sane default, but really, set the ForgetMeNot::Cacheable.cache.  Cacheable expects a cache shaped like an
ActiveSupport::Cacheable::Store


## Origins
This is an extension of the ideas and approach found here:
https://github.com/sferik/twitter/blob/master/lib/twitter/memoizable.rb.  You guys rock.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your code.
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Copyright
(c) 2013 Koan Health. See LICENSE.txt for further details.