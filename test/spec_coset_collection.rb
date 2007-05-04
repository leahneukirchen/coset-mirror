require 'test/spec'

require 'coset'
require 'coset/collection'

require 'atom/feed'             # atom-tools

context "Coset::Collection" do
  specify "should support Arrays" do
    c = Coset::Collection::Array.new([1,2,3])

    c.list.should.equal [1,2,3]
    c.to_a.should.equal [1,2,3]

    c.create(4)
    c.list.should.equal [1,2,3,4]
    
    c << 5
    c.list.should.equal [1,2,3,4,5]

    c.retrieve(1).should.equal 2
    c[1].should.equal 2

    c.update(1, 4)
    c[1].should.equal 4
    c.list.should.equal [1,4,3,4,5]
    c[1] = 5
    c.list.should.equal [1,5,3,4,5]

    c.delete(1)
    c.list.should.equal [1,3,4,5]
  end

  specify "should support Hashes" do
    c = Coset::Collection::Hash.new("name",
                                    {"Simpson" => {"name" => "Simpson",
                                                   "firstname" => "Homer"},
                                      "Newton" => {"name" => "Newton",
                                                   "firstname" => "Isaac"},
                                      })

    c.list.should.equal [{"name" => "Simpson", "firstname" => "Homer"},
                         {"name" => "Newton", "firstname" => "Isaac"}]
    c.to_a.should.equal [{"name" => "Simpson", "firstname" => "Homer"},
                         {"name" => "Newton", "firstname" => "Isaac"}]

    c.create({"name" => "Einstein", "firstname" => "Albert"})
    c.list.should.equal [{"name" => "Simpson", "firstname" => "Homer"},
                         {"name" => "Newton", "firstname" => "Isaac"},
                         {"name" => "Einstein", "firstname" => "Albert"}]
    
    c.retrieve("Newton").should.equal({"name" => "Newton", "firstname" => "Isaac"})
    c["Newton"].should.equal({"name" => "Newton", "firstname" => "Isaac"})

    c.update("Simpson", {"name" => "Simpson", "firstname" => "Thomas"})
    c["Simpson"].should.equal({"name" => "Simpson", "firstname" => "Thomas"})
    c.list.should.equal [{"name" => "Simpson", "firstname" => "Thomas"},
                         {"name" => "Newton", "firstname" => "Isaac"},
                         {"name" => "Einstein", "firstname" => "Albert"}]
    

    c.delete("Simpson")
    c.list.should.equal [{"name" => "Newton", "firstname" => "Isaac"},
                         {"name" => "Einstein", "firstname" => "Albert"}]
  end

  specify "should support Atom" do
    c = Coset::Collection::Atom.new

    c.list.should.equal "<feed xmlns='http://www.w3.org/2005/Atom'/>"

    c.create Atom::Entry.new { |e| e.id = "foo"; e.title = "title of bar" }

    c.list.should.match "<id>foo</id>"
    c["foo"].to_s.should.match "<id>foo</id>"

    c["foo"] = Atom::Entry.new { |e| e.id = "bar"; e.title = "title of bar" }
    c["foo"].to_s.should.match "<id>foo</id>"
    c["foo"].to_s.should.match "<title>title of bar</title>"
  end
end

