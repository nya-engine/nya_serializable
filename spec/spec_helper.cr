require "spec"
require "../src/nya_serializable"

class Biz
  include Nya::Serializable
  property foobar = "fubar"
  
  @[Rename("renamed")]
  property to_rename = "renamed"

  serializable foobar : String

  attribute to_rename : String

  also_known_as biz_alias
end

class Foo
  include Nya::Serializable

  @[Rename("renamedBar")]
  property bar : String = "Baz"
  
  property enabled = true
  property ab = [] of Biz
  attribute enabled : Bool
  serializable bar : String, ab : Array(Biz)
end

class EmbeddedArray
  include Nya::Serializable

  property embed = [] of Biz

  serializator do |this, xml|
    this.embed.each do |elem|
      elem.serialize(xml)
    end
  end

  deserializator do |this, xml|
    xml.xpath_nodes("Biz").each do |node|
      this.embed << Biz.deserialize node
    end
  end
end

class Bar < Foo
  property foo : Foo = Foo.new
  property static_array = StaticArray(Int32, 2).new(0i32)
  serializable foo : Foo, array : Array(Int32), hash : Hash(String, String), static_array : StaticArray(Int32, 2)
  property array = [] of Int32
  property hash = {} of String => String
  property embedded_array = EmbeddedArray.new
  serializable embedded_array : EmbeddedArray
end

class NumberExceptionTest
  include Nya::Serializable
  property num : UInt64 = 0u64
  serializable num : UInt64
end
