require 'coset'

class Coset::Collection < Coset
  def initialize(object=[])
    @object = object
  end

  def to_a
    @object.to_a
  end
  def list
    to_a
  end

  def <<(item)
    @object << item
  end
  def create(item)
    self << item
  end

  def [](index)
    @object[map_index(index)]
  end
  def retrieve(index)
    self[index]
  end
  
  def []=(index, value)
    @object[map_index(index)] = value
  end
  def update(index, value)
    self[index] = value
  end

  def delete(index)
    @object.delete map_index(index)
  end

  def to_s
    @object.to_s
  end

  def map_index(index)
    index
  end
  
  GET "/" do
    res.write list
  end

  POST "/" do
    create req.body
  end

  GET "/{index}" do
    res.write retrieve(@index)
  end

  PUT "/{index}" do
    update(@index, req.body)
  end

  DELETE "/{index}" do
    delete @index
  end
end

class Coset::Collection::Array < Coset::Collection
  def map_index(index)
    Integer(index)
  end

  def delete(index)
    @object.delete_at(map_index(index))
  end
end

class Coset::Collection::Hash < Coset::Collection
  def initialize(pkey, object={})
    super object
    @pkey = pkey
  end
  
  def to_a
    @object.values
  end

  def <<(item)
    update(item.fetch(@pkey), item)
  end
end

class Coset::Collection::Atom < Coset::Collection
  def initialize(feed=::Atom::Feed.new)
    super feed
  end

  def list
    @object.to_s
  end

  def <<(item)
    super(::Atom::Entry.parse(item))
  end

  def [](index)
    @object.entries.find { |e| e.id == index }
  end

  def []=(index, value)
    value.id = index
    self << value
  end

  def delete(index)
    @object.entries.delete_if { |e| e.id == index }
  end
end

