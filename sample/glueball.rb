require 'atom/service'
require 'atom/collection'

require 'rack'
require 'coset'

class Glueball < Coset
  def initialize(svc=Atom::Service.new)
    @svc = svc
  end

  GET "/" do
    res.write '<link rel="service.feed" href="/blogone" />'
    res.write '<link rel="service.post" href="/blogone" />'
  end

  GET "/service.atomsvc" do
    res["Content-Type"] = "application/atomserv+xml"
    res.write @svc.to_s
  end


  class NotFound < IndexError; end
  map_exception NotFound, 404
  
  def feed
    @svc.workspaces.first.collections.find { |feed| feed.id == @feed } or
      raise NotFound
  end

  def entry
    feed.entries.find { |entry| entry.id == @id } or
      raise NotFound
  end


  GET "/{feed}" do
    feed.entries.each { |entry|
      unless entry.edit_url
        link = Atom::Link.new.update "rel" => "edit",
        "href" => "#{feed.id}/#{entry.id}"
        entry.links << link
      end
    }
    
    res["Content-Type"] = "application/atom+xml"
    res.write feed.to_s
  end

  POST "/{feed}" do
    new_entry = Atom::Entry.parse(req.body)

    feed << new_entry
    res["Content-Type"] = "application/atom+xml"
    res.status = 201
    res.write new_entry.to_s
  end

  GET "/{feed}/{id}" do
    res["Content-Type"] = "application/atom+xml"
    res.write entry.to_s
  end

  PUT "/{feed}/{id}" do
    new_entry = Atom::Entry.parse(req.body)
    feed << new_entry
    new_entry.id = @id
    
    res["Content-Type"] = "application/atom+xml"
    res.write new_entry.to_s
  end

  DELETE "/{feed}/{id}" do
    feed.entries.delete_if { |e| e.id == @id }
  end
end


svc = Atom::Service.new
ws = Atom::Workspace.new
col = Atom::Collection.new("/blogone")

svc.workspaces << ws

ws.title = "Glueball server"
ws.collections << col

col.title = "Blog one"
col.id = "blogone"
col << Atom::Entry.new { |e|
  e.id = `uuidgen`.strip
  e.title = "An entry"
  e.content = "the content"
}

app = Glueball.new(svc)
# app = Rack::Lint.new(app)
app = Rack::ShowExceptions.new(app)
app = Rack::ShowStatus.new(app)
app = Rack::CommonLogger.new(app)

Rack::Handler::WEBrick.run app, :Port => 9266
