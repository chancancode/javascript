# JavaScript

As much as we love writing Ruby, when you need to *get closer to the metal*, you
have no choice but to use JavaScript. With this gem, Rubyists can finally
harness the raw power of their machines by programming in JavaScript syntax
*right inside their Ruby applications*.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'javascript'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install javascript

## Usage

```ruby
require "javascript"

puts "This is totally Ruby"

javascript {

  console.log("ZOMG JavaScript");

  var a = 1;

  console.log(a);

  a = a + 1;

  console.log(a);

  var b = function(x) {
    console.log(x + 1);
  };

  b(3);

  function c(x) {
    console.log(x + 2);
  }

  c(4);

  function inspectArguments() {
    var args = Array.prototype.join.call(arguments, ", ");
    console.log("Arguments: " + args);
  }

  inspectArguments("a", "b", "c");

  inspectArguments(1, 2, 3, 4, 5);

}

puts "This is Ruby again"
```

Output:

```
% ruby test.rb
This is totally Ruby
ZOMG JavaScript
1
2
4
6
Arguments: a, b, c
Arguments: 1, 2, 3, 4, 5
This is Ruby again
%
```

### JavaScript + Rails = <3

Because Rails embraces callbacks, this gem is the perfectly compliment for your
Rails application. For example:

```ruby
require "javascript"

class Post < ActiveRecord::Base
  before_create &javascript {
    function(post) {
      post.slug = post.title.parameterize();
    }
  }
end
```

Alternatively:

```ruby
require "javascript"

class Post < ActiveRecord::Base
  before_create &javascript {
    function() {
      this.slug = this.title.parameterize();
    }
  }
end
```

### No Conflict Mode

If the `javascript` helper conflicts with an existing method, you use this gem
in the "no conflict" mode:

```ruby
require "javascript/no_conflict"

# Or add this to your Gemfile:
#
#   gem "javascript", require: "javascript/no_conflict"
#

JavaScript.eval {
  console.log("JavaScript here");
}

# You can also define your own helper method

module Kernel
  private def metal(&block)
    JavaScript.eval(&block)
  end
end

metal {
  console.log("JavaScript here");
}
```

## Pros

* Gives you the illusion of programming in a *closer to the metal* syntax.
* The examples in this README [actually work](/test/javascript_test.rb).
* [![Build Status](https://travis-ci.org/vanruby/javascript.svg)](https://travis-ci.org/vanruby/javascript)

## Cons

* Things that aren't covered in the examples probably won't ever work.
* [Not enough jQuery](http://meta.stackexchange.com/questions/45176/when-is-use-jquery-not-a-valid-answer-to-a-javascript-question).

## Contributing

1. Fork it ( https://github.com/vanruby/javascript/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
