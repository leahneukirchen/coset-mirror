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
  
  def feed(id)
    @svc.workspaces.first.collections.find { |feed| feed.id == @feed } or
      raise IndexError
  end

  def entry(feedid, id)
    feed = feed(feedid).entries.find { |entry| entry.id == @id } or
      raise IndexError
  end

  GET "/{feed}" do
    begin
      feed = feed(@feed)
      feed.entries.each { |entry|
        unless entry.edit_url
          link = Atom::Link.new.update "rel" => "edit",
                                       "href" => "#{feed.id}/#{entry.id}"
          entry.links << link
        end
      }
      
      res["Content-Type"] = "application/atom+xml"
      res.write feed.to_s
    rescue IndexError
      res.status = 404
    end
  end

  POST "/{feed}" do
    feed = feed(@feed)

    new_entry = Atom::Entry.parse(req.body)

    feed << new_entry
    res["Content-Type"] = "application/atom+xml"
    res.write new_entry.to_s
  end

  GET "/{feed}/{id}" do
    begin
      entry = entry(@feed, @id)
      
      res["Content-Type"] = "application/atom+xml"
      res.write entry.to_s
    rescue IndexError
      res.status = 404
    end
  end

  PUT "/{feed}/{id}" do
    begin
      new_entry = Atom::Entry.parse(req.body)
      feed(@feed) << new_entry
      new_entry.id = @id

      res["Content-Type"] = "application/atom+xml"
      res.write new_entry.to_s
    rescue IndexError
      res.status = 406          # not acceptable  (or create?)
    end
  end

  DELETE "/{feed}/{id}" do
    begin
      feed(@feed).entries.delete_if { |e| e.id == @id }
    rescue IndexError
      res.status = 406          # not acceptable
    end
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
# app = Rack::ShowStatus.new(app)
app = Rack::CommonLogger.new(app)

Rack::Handler::WEBrick.run app, :Port => 9266
