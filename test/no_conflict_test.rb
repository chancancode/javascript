require "test_helper"

class NoConflictTest < TestCase
  test "Global `javascript` helper is not available in no-conflict mode" do
    require "javascript/no_conflict"
    assert_raises(NoMethodError) { javascript { 1 } }
  end

  test "Global monkey-patch is not available in no-conflict mode" do
    require "javascript/no_conflict"
    assert_raises(NoMethodError) { JavaScript.eval { Array.prototype } }
  end

  test "Defining custom helper in no-conflict mode" do
    require "javascript/no_conflict"

    def metal(&block)
      JavaScript.eval(&block)
    end

    assert_equal 1, metal { 1 }
  end
end
