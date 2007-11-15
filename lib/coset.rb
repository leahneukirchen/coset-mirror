require 'rack'
require 'pp'

require 'coset/mimeparse'

class Coset
  def call(env)
    @env = env
    path = env["PATH_INFO"]
    path = "/"  if path.empty?
    @res = Rack::Response.new
    @req = Rack::Request.new(env)
    run path, env["REQUEST_METHOD"]
    @res.finish
  end

  def run(path, everb=//)
    @wants = {}
    @wants_content_types = []
    @EXT = ""

    self.class.routes.each { |rx, verb, fields, meth|
      if path =~ rx && everb === verb
        fields.each_with_index { |field, index|
          instance_variable_set "@#{field}", $~[index+1]
        }
        begin
          __send__(meth)
          run_wants  unless @wants.empty?
        rescue *self.class.exceptions.keys => e
          status, message = self.class.exceptions.find_all { |klass, _|
            e.kind_of? klass
          }.sort.first[1]

          res.status = status
          env["rack.showstatus.detail"] = "<h2>" + message + "</h2>"
        end
        return
      end
    }
    res.status = 404
    env["rack.showstatus.detail"] = "<h2>Routes:</h2><pre><code>#{Rack::Utils.escape_html PP.pp(self.class.routes, '')}</code></pre>"
  end

  attr_reader :res, :req, :env

  def wants(type, &block)
    @wants_content_types << type   # keep track of order
    @wants[type] = block
  end

  def run_wants
    # File extensions override Accept:-headers.
    if exttype = Rack::File::MIME_TYPES[@EXT.to_s[1..-1]]
      @env["HTTP_ACCEPT"] = exttype
    end

    # If you accept anything, you'll get the first option.
    @env.delete "HTTP_ACCEPT"  if @env["HTTP_ACCEPT"] == "*/*"
    @env["HTTP_ACCEPT"] ||= @wants_content_types.first

    match = MIMEParse.best_match(@wants_content_types, @env["HTTP_ACCEPT"])

    if match
      @wants[match].call
    else
      res.status = 406          # Not Acceptable
    end
  end

  class << self
    def call(env)
      new.call(env)
    end

    def inherited(newone)
      newone.exceptions = (exceptions || {}).dup
      newone.routes     = (routes     || []).dup
    end

    attr_accessor :exceptions
    attr_accessor :routes

    def define(desc, &block)
      meth = method_name desc
      verb, fields, rx = *tokenize(desc)
      routes << [rx, verb, fields, meth]
      define_method(meth, &block)
    end

    def GET(desc, &block)    define("GET #{desc}", &block)    end
    def POST(desc, &block)   define("POST #{desc}", &block)   end
    def PUT(desc, &block)    define("PUT #{desc}", &block)    end
    def DELETE(desc, &block) define("DELETE #{desc}", &block) end

    def map_exception(exception, status, message="")
      exceptions[exception] = [status, message]
    end

    def tokenize(desc)
      verb, path = desc.split(" ", 2)
      if verb.nil? || path.nil?
        raise ArgumentError, "Invalid description string #{desc}"
      end

      verb.upcase!

      fields = []
      rx = Regexp.new "\\A" + path.gsub(/\{(.*?)(?::(.*?))?\}/) {
        fields << $1

        if $1 == "EXT"
          "(\\.\\w+)?"
        else
          case $2
          when "numeric"
            "(\d+?)"
          when "all"
            "(.*?)"
          when "", nil
            "([^/]*?)"
          else
            raise ArgumentError, "Invalid qualifier #$2 for #$1"
          end
        end
      } + "\\z"

      [verb, fields, rx]
    end

    def method_name(desc)
      desc.gsub(/\{(.*?)\}/) { $1.upcase }.delete(" ").gsub(/[^\w-]/, '_')
    end
  end
end
