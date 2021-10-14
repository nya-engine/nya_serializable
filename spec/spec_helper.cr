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
  
  property enabled = false
  property ab = [] of Biz
  attribute enabled : Bool
  serializable bar : String, ab : Array(Biz)
end

class Bar < Foo
  property foo : Foo = Foo.new
  property static_array = StaticArray(Int32, 2).new(0i32)
  serializable foo : Foo, array : Array(Int32), hash : Hash(String, String), static_array : StaticArray(Int32, 2)
  property array = [] of Int32
  property hash = {} of String => String
end
