require "./spec_helper"

EXAMPLE_XML = File.read(File.join(File.dirname(__FILE__), "example.xml")).gsub(/[\t\n]/,"")

describe Nya::Serializable do
  it "registers classes" do
    Nya::Serializable.children.keys.should eq(%w(Biz Foo Bar))
  end

  it "deserializes objects" do
    obj = Bar.deserialize(EXAMPLE_XML)
    obj.bar.should eq("9")
    obj.foo.bar.should eq("Biz")
    obj.array.should eq([1,2,3])
    obj.hash.should eq({"one" => "1", "two" => "2"})
    obj.enabled.should eq(true)
    obj.foo.enabled.should eq(false)
    obj.foo.ab.map(&.foobar).should eq(["foo foo", "bar bar"])
    obj.static_array.to_a.should eq([1, 2])
  end

  it "serializes objects" do
    obj = Bar.new
    obj.foo.bar = "Biz"
    obj.bar = "9"
    obj.array = [1,2,3]
    obj.hash = {"one" => "1", "two" => "2"}
    obj.foo.ab = [Biz.new, Biz.new]
    obj.foo.ab[0].foobar = "foo foo"
    obj.foo.ab[1].foobar = "bar bar"
    obj.enabled = true
    obj.static_array = StaticArray(Int32, 2).new{ |i| i + 1 }
    obj.serialize.gsub(/[\t\n]/, "").should eq(EXAMPLE_XML)
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
      "static_array" => "StaticArray(Int32, 2)"
      }))

    Biz.properties.should eq({"foobar" => "String"})
  end
end
