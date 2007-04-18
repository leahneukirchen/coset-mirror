require 'pp'

class Coset
  @@routes = []  unless defined? @@routes

  def call(env)
    path = env["PATH_INFO"]
    path = "/"  if path.empty?
    @res = Rack::Response.new
    @req = Rack::Request.new(env)
    run path, env["REQUEST_METHOD"]
    @res.finish
  end

  def run(path, everb=//)
    @@routes.each { |rx, verb, fields, meth|
      if path =~ rx && everb === verb
        fields.each_with_index { |field, index|
          instance_variable_set "@#{field}", $~[index+1]
        }
        return __send__(meth)
      end
    }
    res.status = 404
    req.env["rack.showstatus.detail"] = "<h2>Routes:</h2><pre><code>#{Rack::Utils.escape_html PP.pp(@@routes, '')}</code></pre>"
  end

  attr_reader :res, :req

  class << self
    def call(env)
      new.call(env)
    end
    
  def define(desc, &block)
    meth = method_name desc
    verb, fields, rx = *tokenize(desc)
    @@routes << [rx, verb, fields, meth]
    define_method(meth, &block)
  end

  def GET(desc, &block)
    define("GET #{desc}", &block)
  end
  def POST(desc, &block)
    define("POST #{desc}", &block)
  end
  def PUT(desc, &block)
    define("PUT #{desc}", &block)
  end
  def DELETE(desc, &block)
    define("DELETE #{desc}", &block)
  end

  def tokenize(desc)
    verb, path = desc.split(" ", 2)
    if verb.nil? || path.nil?
      raise ArgumentError, "Invalid description string #{desc}"
    end

    verb.upcase!

    fields = []
    rx = Regexp.new "\\A" + path.gsub(/\{(.*?)(:.*?)?\}/) {
      fields << $1
      case $2
      when "numeric"
        "(\d+)"
      when "all"
        "(.*?)"
      when "", nil
        "([^/]*?)"
      else
        raise ArgumentError, "Invalid qualifier #$2 for #$1"
      end
    } + "\\z"

    [verb, fields, rx]
  end

  def method_name(desc)
    desc.gsub(/\{(.*?)\}/) { $1.upcase }.delete(" ").gsub(/[^\w-]/, '_')
  end
  
  end
end
