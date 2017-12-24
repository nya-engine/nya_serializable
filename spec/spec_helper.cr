require "spec"
require "../src/nya_serializable"

class Biz
  include Nya::Serializable
  property foobar = "fubar"
  serializable foobar : String
end

class Foo
  include Nya::Serializable
  property bar : String = "Baz"
  property enabled = false
  property ab = [] of Biz
  attribute enabled : Bool
  serializable bar : String, ab : Array(Biz)
end

class Bar < Foo
  property foo : Foo = Foo.new
  serializable foo : Foo, array : Array(Int32), hash : Hash(String, String)
  property array = [] of Int32
  property hash = {} of String => String
end
