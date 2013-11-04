# ForgetMeNot

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

Memoization is intended to allow a single object instance to remember the result of a method call.  If you have
ever written something like:

    def full_name
      @full_name ||= "#{last_name}, #{first_name}"
	end

then you have done memoization.  The result is calculated the first time full_name is called.  Subsequent calls return
the same value and do not incur the overhead of calculating the result.  Trivial in this case, but the work could be quite
substantial.

Caching is similar, but broader in scope.  For us, the initial use case was a dashboard in one of our products that aggregated the numerical
values of several hundred thousand medical claims.  Rather than performing this query every time we generate the dashboard,
we cached the results of the query allowing us to display the web page in a snap.

Our caching mixin is intended to be used with a cache like memcached that is available across your servers.  It includes
convenience methods to allow cache warming.

## Usage

### Memoizable Mixin
TODO

### Cacheable Mixin
TODO

## Origins
This is an extension of the ideas and approach that were encoded
https://github.com/sferik/twitter/blob/master/lib/twitter/memoizable.rb.  You guys rock.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright
(c) 2013 Koan Health. See LICENSE.txt for further details.