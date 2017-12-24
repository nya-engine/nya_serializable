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
    obj.serialize.gsub(/[\t\n]/, "").should eq(EXAMPLE_XML)
  end
end
