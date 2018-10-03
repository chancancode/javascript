require "javascript/version"
require "binding_of_caller"

def supress_warnings
  verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = verbose
end

module JavaScript
  def self.eval(&block)
    Scope.new.__eval__(&block)
  end

  def self.current_scope
    @scope
  end

  def self.current_scope=(scope)
    @scope = scope
  end

  # Make it an `Object` instead of `BasicObject` so that we can bind
  # any instance methods from `Object` and call them here
  class BlankObject
    supress_warnings do
      instance_methods(true).each { |meth| undef_method(meth) }
      private_instance_methods(true).each { |meth| undef_method(meth) }
    end
  end

  module Internals
    supress_warnings do
      def __send__(meth, *args, &block)
        __method__(:public_send).call(meth, *args, &block)
      end
    end

    private
      def __method__(name)
        ::Object.instance_method(name).bind(self)
      end

      def __binding__
        __method__(:binding).call.of_caller(1)
      end

      def __caller__
        __binding__.of_caller(2)
      end
  end

  class Object < BlankObject
    include Internals

    def initialize(proto = nil)
      @hash = { __proto__: proto }
    end

    def [](key)
      if @hash.key?(key)
        @hash[key]
      elsif __proto__
        __proto__[key]
      else
        nil
      end
    end

    def []=(key, value)
      @hash[key.to_sym] = value
    end

    def ==(other)
      __method__(:==).call(other)
    end

    def ===(other)
      self == other
    end

    def !=(other)
      !(self == other)
    end

    def __hash__
      @hash
    end

    def __proto__
      @hash[:__proto__]
    end

    def __defined__?(key)
      @hash.key?(key) || (__proto__ && __proto__.__defined__?(key))
    end

    private
      def method_missing(name, *args, &block)
        if name =~ /=\z/
          self[name[0...-1].to_sym] = args[0]
        elsif Function === self[name]
          self[name].apply(self, args)
        else
          self[name]
        end
      end
  end

  class GlobalObject < Object
    def initialize
      super
      @hash[:console] = Console.new
    end
  end

  module Syntax
    private
      def window
        @global
      end

      def global
        @global
      end

      def this
        @target
      end

      def undefined
        nil
      end

      def let(*identifiers)
      end

      def var(*identifiers)
      end

      def new(identifier)
        ::Object.const_get(identifier.name).new(*identifier.args)
      end

      def function(*args, &block)
        if args.length == 1 && Function === args[0]
          hash = @parent ? @locals : global.__hash__
          hash[args[0].name] = args[0]
        else
          Function.new(nil, args, block)
        end
      end
  end

  class Scope < BlankObject
    include Internals
    include Syntax

    def initialize(parent = nil, target = nil, locals = {})
      @parent = parent
      @global = parent ? parent.__global__ : GlobalObject.new
      @locals = locals

      if Scope === target
        @target = target.__target__
      else
        @target = target || global
      end
    end

    def __global__
      @global
    end

    def __target__
      @target
    end

    def __spawn__(target = nil, locals = {})
      Scope.new(self, target, locals)
    end

    def __eval__(*args, &block)
      JavaScript.current_scope = self

      # convert the block to a lambda, so that +return+ works correctly
      temp      = :"block_#{Time.now.to_i}"
      metaclass = __method__(:singleton_class).call

      metaclass.send(:define_method, temp, &block)

      if block.arity.zero?
        __method__(:send).call(temp)
      else
        __method__(:send).call(temp, *args)
      end
    ensure
      JavaScript.current_scope = @parent
      metaclass.send(:remove_method, temp)
    end

    private
      def method_missing(name, *args, &block)
        found   = false
        value   = nil
        defined = __caller__.local_variable_defined?(name) rescue nil

        if defined
          found = true
          value = __caller__.local_variable_get(name)
        elsif @locals.key?(name)
          found = true
          value = @locals[name]
        elsif !@parent && @global.__defined__?(name)
          found = true
          value = @global[name]
        end

        if found && Function === value
          value.apply(nil, args)
        elsif found
          value
        elsif @parent
          @parent.__send__(name, *args, &block)
        elsif block.nil?
          Identifier.new(name, args)
        else
          Function.new(name, args, block)
        end
      end
  end

  class Identifier < Struct.new(:name, :args); end

  class Function < Struct.new(:name, :args, :body)
    def initialize(*)
      @scope = JavaScript.current_scope
      super
    end

    def arity
      args.length
    end

    def call(target = nil, *arg_values)
      ::Object.instance_method(:instance_exec).bind(target).call(*arg_values, &self)
    end

    def apply(target = nil, arg_values)
      call(target, *arg_values)
    end

    def bind(target)
      BoundFunction.new(target, name, args, body)
    end

    def to_proc
      parent_scope = @scope
      arg_names    = args.map(&:name)
      unwrapped    = body

      FunctionWrapper.new(arg_names) do |*arg_values|
        locals = Hash[ arg_names.zip(arg_values) ]
        locals[:arguments] = arg_values
        parent_scope.__spawn__(self, locals).__eval__(*arg_values, &unwrapped)
      end
    end
  end

  class BoundFunction < Function
    def initialize(target, name, args, body)
      super(name, args, body)
      @target = target
    end

    def call(_, *arg_values)
      super(@target, *arg_values)
    end

    def apply(_, arg_values)
      super(@target, arg_values)
    end

    def bind(_)
      self
    end
  end

  class FunctionWrapper < Proc
    def initialize(args, &block)
      @args = args
      super(&block)
    end

    def arity
      @args.length
    end

    def parameters
      @args.map { |arg| [:required, arg.to_sym] }
    end
  end

  class Prototype < Object
    def initialize(klass)
      super(nil)
      @klass = klass
    end

    private
      def method_missing(name, *args, &block)
        meth = @klass.instance_method(name)
        args = meth.parameters.map { |_, name| name && Identifier.new(name) }.compact
        body = ->(*args) { meth.bind(this).call(*args) }
        Function.new(name, args, body)
      rescue NameError
        super
      end
  end

  class Console
    def log(*args)
      puts(*args)
    end
  end
end

unless defined?(JavaScript::NO_CONFLICT)
  module Kernel
    def javascript(&block)
      JavaScript.eval(&block)
    end
  end

  class Class
    def prototype
      JavaScript::Prototype.new(self)
    end
  end
end
