# nya_serializable

Serializable module for [Nya Engine](https://github.com/unn4m3d/nya_engine)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  nya_serializable:
    github: unn4m3d/nya_serializable
```

## Usage

```crystal
require "nya/serializable"

class Foo
  include Nya::Serializable

  serializable foo : Bar, bar : Array(String)
  attribute fubar : String
end
```

Then you can `#serialize` it to something like that

```xml
<Foo fubar="unn4m3d">
  <foo>
    <Bar>
      ...
    </Bar>
  </foo>
  <bar>
    <item>foo</item>
    <item>foo bar</item>
  </bar>
</Foo>
```

And deserialize that XML into structure above with `Nya::Serializable.deserialize(Foo)`

## Contributing

1. Fork it ( https://github.com/unn4m3d/nya_serializable/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [unn4m3d](https://github.com/unn4m3d) - creator, maintainer
