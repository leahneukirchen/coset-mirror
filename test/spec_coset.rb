require 'test/spec'

require 'rack'
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

context "Coset" do
  specify "should parse Accept-headers correctly" do

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5;v=1"})
    res.should.match "HTML"

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5;v=1,text/plain"})
    res.should.match "ASCII"

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/html ;q=0.5,text/plain;q=0.2"})
    res.should.match "HTML"

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "text/*"})
    res.should.match "HTML"     # first choice

    res = Rack::MockRequest.new(TestApp).
      get("/index", {"HTTP_ACCEPT" => nil})
    res.should.match "HTML"     # first choice

    res = Rack::MockRequest.new(TestApp).
      get("/index.html", {"HTTP_ACCEPT" => "x-noidea/x-whatthisis"})
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
end
