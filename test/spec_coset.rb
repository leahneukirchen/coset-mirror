require 'test/spec'

require 'coset'

class TestApp < Coset
  GET "/{path}{EXT}" do
    wants("text/html") { res.write "HTML" }
    wants("text/plain") { res.write "ASCII" }
  end
end

class TestApp2 < Coset
  map_exception IndexError, 404
  map_exception NameError, 500
  
  GET "/ie" do
    raise IndexError
  end

  GET "/urgs" do
    res.write "meh"
    quux!
  end
end

class FooApp < Coset
  GET "/foo" do
    res.write "foo"
  end

  GET "/a" do
    res.write "a"
  end

  GET "/duh" do
    raise IndexError
  end

  map_exception IndexError, 500
end

class BarApp < FooApp
  GET "/bar" do
    res.write "bar"
  end

  GET "/a" do
    res.write "b"
  end

  map_exception IndexError, 404
end

context "Coset" do
  specify "should parse Accept-headers correctly" do

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5;v=1"})
    res.should.match "HTML"

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5,text/plain;q=0.2"})
    res.should.match "HTML"

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5;v=1,text/plain"})
    res.should.match "HTML"     # extension overrides

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/*"})
    res.should.match "HTML"     # first choice

    res = Rack::MockRequest.new(TestApp).
      get("/index", {"HTTP_ACCEPT" => nil})
    res.should.match "HTML"     # first choice

    res = Rack::MockRequest.new(TestApp).
      get("/index", {"HTTP_ACCEPT" => "x-noidea/x-whatthisis"})
    res.status.should.equal 406 # not acceptable

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => nil})
    res.should.match "HTML"     # extension

    res = Rack::MockRequest.new(TestApp).
      get("/index.txt", {"HTTP_ACCEPT" => nil})
    res.should.match "ASCII"     # extension
      
  end

  specify "should map exceptions" do
    res = Rack::MockRequest.new(TestApp2).
      get("/ie")
    res.status.should.equal 404

    res = Rack::MockRequest.new(TestApp2).
      get("/urgs")
    res.status.should.equal 500
  end

  specify "should support inheritance properly" do
    BarApp.ancestors.should.include FooApp
    BarApp.ancestors.should.include Coset
    
    res = Rack::MockRequest.new(BarApp).get("/foo")
    res.should.match "foo"

    res = Rack::MockRequest.new(BarApp).get("/bar")
    res.should.match "bar"

    res = Rack::MockRequest.new(FooApp).get("/a")
    res.should.match "a"
    res = Rack::MockRequest.new(BarApp).get("/a")
    res.should.match "b"

    res = Rack::MockRequest.new(FooApp).get("/duh")
    res.status.should.equal 500
    res = Rack::MockRequest.new(BarApp).get("/duh")
    res.status.should.equal 404
  end
end
