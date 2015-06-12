require "test_helper"

$messages = []

module JavaScript
  class Console
    private def puts(message)
      $messages << message
    end
  end
end

class JavaScriptTest < TestCase
  teardown do
    $messages.clear
  end

  test "undefined" do
    require "javascript"
    assert_nil javascript { undefined }
  end

  test "this" do
    require "javascript"

    javascript do
      console.log(this === window);
      console.log(this === global);
    end

    assert_messages true, true
  end

  test "Local variables" do
    require "javascript"

    javascript {
      var a = 1, b = 2;

      console.log(a);
      console.log(b);

      a = a + 1;
      b = a + b;

      console.log(a);
      console.log(b);
    }

    assert_messages 1, 2, 2, 4
  end

  test "Global variables" do
    require "javascript"

    javascript {
      window.a = 1;
      global.b = 2;

      console.log(a);
      console.log(b);

      console.log(a === window.a);
      console.log(a === global.a);

      console.log(b === window.b);
      console.log(b === global.b);
    }

    assert_messages 1, 2, true, true, true, true
  end

  test "Global object is not shared between different javascript blocks" do
    require "javascript"

    javascript { window.a = 1; }
    assert_nil javascript { window.a; }
  end

  test "Functions" do
    require "javascript"

    javascript {
      var a = function(msg) {
        console.log("a: " + msg);
      };

      function b(msg) {
        console.log("b: " + msg);
      }

      var c = "c";

      a("hello");
      b("hello");

      a(c);
      b(c);
    }

    assert_messages "a: hello", "b: hello", "a: c", "b: c"
  end

  test "Functions can return a value" do
    require "javascript"

    javascript {
      function identity(x) {
        return x;
      }

      function square(x) {
        return x * x;
      }

      console.log(identity("Hello world!"));
      console.log(square(2));
    }

    assert_messages "Hello world!", 4
  end

  test "closure" do
    require "javascript"

    javascript {
      var a = 1;

      function outer(b) {
        var c = 3;

        function inner(d) {
          var e = 5;

          console.log(a);
          console.log(b);
          console.log(c);
          console.log(d);
          console.log(e);
        };

        return inner(4);
      }

      outer(2);
    }

    assert_messages 1, 2, 3, 4, 5
  end

  test "arguments" do
    require "javascript"

    javascript {
      function inspect() {
        console.log(arguments.length);
        console.log(arguments);
      }

      inspect("a", "b", "c");
      inspect(1, 2, 3, 4, 5);
      inspect();
    }

    assert_messages 3, ["a", "b", "c"], 5, [1, 2, 3, 4, 5], 0, []
  end

  test "Function#call" do
    require "javascript"

    javascript do
      var thisCheck = function(expected) {
        console.log(this === expected);
      };

      thisCheck(this);
      thisCheck("abc");

      thisCheck.call(this, this);
      thisCheck.call(this, "abc");

      thisCheck.call("abc", "abc");
      thisCheck.call("abc", this);

      var argsCheck = function() {
        console.log(this == arguments);
      };

      argsCheck.call([1, 2, 3], 1, 2, 3);
      argsCheck.call([1, 2, 3], 4, 5, 6);
      argsCheck.call([1, 2, 3], [1, 2, 3]);
    end

    assert_messages true, false, true, false, true, false, true, false, false
  end

  test "Function#apply" do
    require "javascript"

    javascript do
      var thisCheck = function(expected) {
        console.log(this === expected);
      };

      thisCheck(this);
      thisCheck("abc");

      thisCheck.apply(this, [this]);
      thisCheck.apply(this, ["abc"]);

      thisCheck.apply("abc", ["abc"]);
      thisCheck.apply("abc", [this]);

      var argsCheck = function() {
        console.log(this == arguments);
      };

      argsCheck.apply([1, 2, 3], [1, 2, 3]);
      argsCheck.apply([1, 2, 3], [4, 5, 6]);
    end

    assert_messages true, false, true, false, true, false, true, false
  end

  test "Function#bind" do
    require "javascript"

    javascript do
      var thisCheck = function(expected) {
        console.log(this === expected);
      };

      thisCheck = thisCheck.bind("abc");

      thisCheck(this);
      thisCheck("abc");

      thisCheck.call(this, this);
      thisCheck.call(this, "abc");
      thisCheck.call("abc", "abc");

      var argsCheck = function() {
        console.log(this == arguments);
      };

      argsCheck = argsCheck.bind([1, 2, 3]);

      argsCheck.call("abc", 1, 2, 3);
      argsCheck.apply("abc", [1, 2, 3]);

      argsCheck.call("abc", 4, 5, 6);
      argsCheck.apply("abc", [4, 5, 6]);
    end

    assert_messages false, true, false, true, true, true, true, false, false
  end

  test "Prototype" do
    require "javascript"

    javascript {
      var join = Array.prototype.join;

      console.log(join.call(["a", "b", "c"], "+"));
      console.log(join.call([1, 2, 3, 4, 5], "-"));
    }

    assert_messages "a+b+c", "1-2-3-4-5"
  end

  test "Callback" do
    require "javascript"
    require "active_support/callbacks"
    require "active_support/core_ext/string/inflections"

    class Post < Struct.new(:title, :slug)
      include ActiveSupport::Callbacks

      define_callbacks :create, :destroy

      set_callback :create, :before, &javascript {
        function(post) {
          console.log("Before");
          post.slug = post.title.parameterize();
        }
      }

      set_callback :destroy, :after, &javascript {
        function() {
          console.log("After");
          this.slug = undefined;
        }
      }

      def create
        run_callbacks(:create)
      end

      def destroy
        run_callbacks(:destroy)
      end
    end

    post = Post.new("Hello world!")

    assert_nil post.slug

    post.create

    assert_equal "hello-world", post.slug

    post.destroy

    assert_nil post.slug

    assert_messages "Before", "After"
  end

  private
    def assert_messages(*messages)
      assert_equal messages, $messages
    end
end
