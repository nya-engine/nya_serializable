require "spec"
require "../src/nya/serializable"

class Foo
  include Nya::Serializable
  property bar : String = "Baz"
  property enabled = false
  attribute enabled : Bool
  serializable bar : String


end

class Bar < Foo
  property foo : Foo = Foo.new
  serializable foo : Foo, array : Array(Int32), hash : Hash(String, String)
  property array = [] of Int32
  property hash = {} of String => String
end
