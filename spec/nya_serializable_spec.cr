require "./spec_helper"

INPUT_XML = File.read(File.join(File.dirname(__FILE__), "example.xml")).gsub(/[\t\n]/,"")
OUTPUT_XML = File.read(File.join(File.dirname(__FILE__), "example copy.xml")).gsub(/[\t\n]/,"")


describe Nya::Serializable do
  it "registers classes" do
    Nya::Serializable.children.keys.should eq(%w(Biz biz_alias Foo EmbeddedArray Bar))
  end

  it "deserializes objects" do
    obj = Bar.deserialize(INPUT_XML)
    obj.bar.should eq("9")
    obj.foo.bar.should eq("Biz")
    obj.array.should eq([1,2,3])
    obj.hash.should eq({"one" => "1", "two" => "2"})
    obj.enabled.should eq(true)
    obj.foo.enabled.should eq(false)
    obj.foo.ab.map(&.foobar).should eq(["foo foo", "bar bar"])
    obj.foo.ab.map(&.to_rename).should eq(["renamed", "really?"])
    obj.static_array.to_a.should eq([1, 2])
    obj.embedded_array.embed.first.to_rename.should eq("1")
  end

  it "serializes objects" do
    obj = Bar.new
    obj.foo.bar = "Biz"
    obj.bar = "9"
    obj.array = [1,2,3]
    obj.hash = {"one" => "1", "two" => "2"}
    obj.foo.ab = [Biz.new, Biz.new]
    obj.foo.ab[0].foobar = "foo foo"
    obj.foo.ab[1].to_rename = "really?"
    obj.foo.ab[1].foobar = "bar bar"
    obj.enabled = true
    obj.static_array = StaticArray(Int32, 2).new{ |i| i + 1 }
    obj.serialize.gsub(/[\t\n]/, "").should eq(OUTPUT_XML)
  end

  it "generates info about properties" do
    Foo.properties.should eq({
      "bar" => "String",
      "ab" => "Array(Biz)",
      "enabled" => "$Bool"
    })

    Bar.properties.should eq(Foo::PROPERTIES.merge({
      "foo" => "Foo",
      "array" => "Array(Int32)",
      "hash" => "Hash(String, String)",
      "static_array" => "StaticArray(Int32, 2)",
      "embedded_array" => "EmbeddedArray"
      }))

    Biz.properties.should eq({"foobar" => "String", "to_rename" => "$String"})
  end

  it "deserializes numbers with different bases" do 
    Nya::Serializable.parse_number("100", UInt64).should eq(100u64)
    Nya::Serializable.parse_number("0xDEADF00D", UInt32).should eq(0xDEADF00Du32)
    Nya::Serializable.parse_number("0123", UInt8).should eq(0o123u8)
    Nya::Serializable.parse_number("0b00111110", UInt8).should eq(0x3Eu8)
    Nya::Serializable.parse_number("-257", Int16).should eq(-257i16)  
  end
end
