# coding: utf-8
class Executor
  GREETINGS = [
    'salutations', 'greetings', 'pleasant', 'welcome', 'hey there',
    'hello there', 'welcome, welcome', 'hello'
  ].freeze

  NO_COMMAND = [
    'what?', 'why do you call for me?', 'what would you like for me to do?',
    'what would you ask of me?', 'what do you want?',
    'are you trying to bother me?', 'you cannot escape', 'i am listening',
    'i am always here of course', 'what can I do for you?', 'i am not amused',
    'what do you require?', 'i can no longer contain my rage', 'sometimes I get tired'
  ].freeze

  POETRY = [
    "\"Doubt thou the stars are fire;\nDoubt that the sun doth move;\nDoubt truth to be a liar;\nBut never doubt I love.\"\n- William Shakespeare",
    "“There is a pleasure in the pathless woods,\n
      There is a rapture on the lonely shore,\n
      There is society, where none intrudes,\n
      By the deep sea, and music in its roar:\n
      I love not man the less, but Nature more”\n
      - Lord Byron"
  ].freeze

  RUBY_CORE_CLASSES = %w(
    ARGF
    ArgumentError
    Array
    BasicObject
    Bignum
    Binding
    Class
    Comparable
    Complex
    Continuation
    Data
    Dir
    ENV
    EOFError
    Encoding
    Encoding::CompatibilityError
    Encoding::Converter
    Encoding::ConverterNotFoundError
    Encoding::InvalidByteSequenceError
    Encoding::UndefinedConversionError
    EncodingError
    Enumerable
    Enumerator
    Enumerator::Generator
    Enumerator::Yielder
    Errno
    Exception
    FalseClass
    Fiber
    FiberError
    File
    File::Constants
    File::Stat
    FileTest
    Fixnum
    Float
    FloatDomainError
    GC
    GC::Profiler
    Hash
    IO
    IO::WaitReadable
    IO::WaitWritable
    IOError
    IndexError
    Integer
    Interrupt
    Kernel
    KeyError
    LoadError
    LocalJumpError
    Marshal
    MatchData
    Math
    Math::DomainError
    Method
    Module
    Mutex
    NameError
    NilClass
    NoMemoryError
    NoMethodError
    NotImplementedError
    Numeric
    Object
    ObjectSpace
    Proc
    Process
    Process::GID
    Process::Status
    Process::Sys
    Process::UID
    Random
    Range
    RangeError
    Rational
    Regexp
    RegexpError
    RubyVM
    RubyVM::Env
    RubyVM::InstructionSequence
    RuntimeError
    ScriptError
    SecurityError
    Signal
    SignalException
    StandardError
    StopIteration
    String
    Struct
    Symbol
    SyntaxError
    SystemCallError
    SystemExit
    SystemStackError
    Thread
    ThreadError
    ThreadGroup
    Time
    TrueClass
    TypeError
    UnboundMethod
    ZeroDivisionError
    fatal
    unknown).freeze

  JS_BUILTIN_OBJECTS = %w(
    global_objects
    Array
    ArrayBuffer
    Atomics
    Boolean
    DataView
    Date
    Error
    EvalError
    Float32Array
    Float64Array
    Function
    Generator
    GeneratorFunction
    Infinity
    Int16Array
    Int32Array
    Int8Array
    InternalError
    Intl
    Collator
    DateTimeFormat
    NumberFormat
    Iterator
    JSON
    Map
    Math
    NaN
    Number
    Object
    ParallelArray
    Promise
    Proxy
    RangeError
    ReferenceError
    Reflect
    RegExp
    SIMD
    Bool16x8
    Bool32x4
    Bool64x2
    Bool8x16
    Float32x4
    Float64x2
    Int16x8
    Int32x4
    Int8x16
    Uint16x8
    Uint32x4
    Uint8x16
    Set
    SharedArrayBuffer
    StopIteration
    String
    Symbol
    SyntaxError
    TypeError
    TypedArray
    URIError
    Uint16Array
    Uint32Array
    Uint8Array
    Uint8ClampedArray
    WeakMap
    WeakSet
    decodeURI
    decodeURIComponent
    encodeURI
    encodeURIComponent
    escape
    eval
    isFinite
    isNaN
    null
    parseFloat
    parseInt
    undefined
    unescape
    uneval).freeze

  LINKME_DOCS = 'This command takes the form:' \
                "\n`halbot -l|linkme [Ruby|Javascript/JS] [core/class/stdlib|ref/object]`" \
                "\n\nRuby only supports core classes and the *indexes* of core-ruby and the standard library." \
                "\n\nJavascript only supports built-in objects and the JS reference *index*." \
                "\n\nIf no option is provided for the language, core-ruby or JS reference is used by default.".freeze

  def initialize(event_data)
    @user_id = event_data['user']
    @commands = event_data['text'].strip.split(' ')[1..-1]
  end

  def parse
    main_command = @commands.first
    case main_command
    when nil, 'help'
      no_commands
    when 'greet'
      greet
    when 'linkme', '-l'
      linkme
    when 'roll'
      roll
    # when 'poetry'
    #   @poetry.sample
    else
      'I do not understand...'
    end
  end

  private

  def no_commands
    Executor::NO_COMMAND.sample.capitalize
  end

  def greet
    Executor::GREETINGS.sample.capitalize + ", <@#{@user_id}>"
  end

  def linkme
    lang = @commands[1].downcase if @commands[1]
    option = @commands[2]
    if lang == 'ruby'
      version = '2.3.1'
      return "http://www.ruby-doc.org/stdlib-#{version}" if option == 'stdlib'
      return "http://www.ruby-doc.org/core-#{version}/" if [nil, 'core'].include? option

      Executor::RUBY_CORE_CLASSES.each do |c|
        if c.casecmp(option) >= 0
          return "http://www.ruby-doc.org/core-#{version}/#{c.gsub(/::/, '/')}.html"
        end
      end
      "http://www.ruby-doc.org/core-#{version}/"

    elsif lang == 'javascript' || lang == 'js'
      objs_link = 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/'
      ref_link = 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/'
      if Executor::JS_BUILTIN_OBJECTS.select { |o| o.downcase == option }.any?
        return objs_link if option == 'global_objects'
        objs_link + option.to_s
      else
        ref_link
      end
    else
      Executor::LINKME_DOCS
    end
  end

  def roll
    "*#{(1..100).to_a.sample}*"
  end
end
