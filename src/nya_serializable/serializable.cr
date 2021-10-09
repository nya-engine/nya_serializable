require "xml"
require "log"
require "./serializable/*"

module Nya
  module Serializable
    # :nodoc:
    alias Node = XML::Node

    # :nodoc:
    alias Builder = XML::Builder

    # :nodoc:
    alias Serializator = Builder, self ->

    # :nodoc:
    alias Deserializator = Node, self ->

    # :nodoc:
    protected def deserialize_props!(node : Node, ctx : SerializationContext?)
    end

    # :nodoc:
    protected def serialize_props!(builder : Builder, ctx : SerializationContext?)
    end

    # :nodoc:
    protected def serialize_attrs!(builder : Builder, ctx : SerializationContext?)
    end

    @@children = {} of String => (Node, SerializationContext? -> Serializable)

    # :nodoc:
    class_getter children

    @@log = Log.for(self)

    class_property log

    # :nodoc:
    protected def self.debug(str)
      {% if env("N_S_DEBUG") == "1" %}
        puts str
      {% end %}
    end

    # Translates Crystal type name into XML compatible tag name
    #
    # Converts first part of a `Fully::Qualified::Name` into a XML namespace 
    # and joins the rest with underscores, like `Fully:Qualified_Name`.
    # Converts generic type names like `Generic(A, B)` into `Generic..A.B-`.
    #
    # WARNING: This macro is intended for internal use, generic type conversion is
    # currently not used in the library and may be removed in future.
    #
    # NOTE: Type must be a `StringLiteral`, `Generic`, `Path`, or just an 
    # unqualified `MacroId`. In the latter case, type name is just stringified
    # without any conversion.
    macro translate_type(type)
      {% if type.is_a? StringLiteral %}
        translate_type {{type.id}}
      {% elsif type.is_a? Generic %}
        (
          {% vs = type.type_vars %}
          %name = Nya::Serializable.translate_type {{type.name}}
          "#{%name}.." + {% for i in (0...vs.size) %}\
            {% e = vs[i] %}""{% if i > 0 %}+"."{% end %}\
            + Nya::Serializable.translate_type({{e}}) + {% end %} "-"
        )
      {% elsif type.is_a? Path %}
        {% names = type.names %}
        {% namespace = names[0...-1].map{ |x| x.stringify}.join('_') %}
        {% if names.size == 1 %}
          {{ names.last.stringify}}
        {% else %}
          {{ namespace + ":" + names.last.stringify}}
        {% end %}
      {% else %}
        {{ type.id.stringify }}
      {% end %}
    end

    # :nodoc:
    macro register
      {% unless @type.has_constant? :NYA_REGISTERED %}
        PROPERTIES = {} of String => String
        {% typename = @type.stringify.gsub(/(::|[(),])/, "_").id %}

        @@_deserialize_{{typename}} = [] of Deserializator

        # :nodoc:
        protected class_getter _deserialize_{{typename}}

        @@_serialize_{{typename}} = [] of Serializator

        # :nodoc:
        protected class_getter _serialize_{{typename}}

        @@_serialize_attrs_{{typename}} = [] of Serializator

        # :nodoc:
        protected class_getter _serialize_attrs_{{typename}}

        @_serialization_context : SerializationContext? = nil

        # :nodoc:
        protected def deserialize_props!(node : Node, context : SerializationContext? = nil)
          ::Nya::Serializable.debug "Deserializing props in #{self.class.name} ({{@type}}, #{@@_deserialize_{{typename}}.size} procs)"
          {% if @type.superclass < ::Nya::Serializable %}
            super node, context
          {% end %}

          @_serialization_context = context
          {{@type}}._deserialize_{{typename}}.each &.call(node, self.as(::Nya::Serializable))
        end

        # :nodoc:
        protected def serialize_props!(builder : Builder, ctx : SerializationContext? = nil)
          {% if @type.superclass < ::Nya::Serializable %}
            super builder, ctx
          {% end %}

          @_serialization_context = ctx

          {{@type}}._serialize_{{typename}}.each &.call(builder, self.as(::Nya::Serializable))
        end

        # :nodoc:
        protected def serialize_attrs!(builder : Builder, ctx : SerializationContext? = nil)
          {% if @type.superclass < ::Nya::Serializable %}
            super builder, ctx
          {% end %}

          @_serialization_context = ctx

          {{@type}}._serialize_attrs_{{typename}}.each &.call(builder, self.as(::Nya::Serializable))
        end


        ::Nya::Serializable.children[self.xml_name] = ->(n : Node, c : SerializationContext?) do
          ::Nya::Serializable.debug "Call child #{self.xml_name}"
          obj = self.new
          obj.deserialize_props! n, c
          obj.as(::Nya::Serializable)
        end

        # Returns XML compatible name of a type (see `Nya::Serializable.translate_type`)
        def self.xml_name
          ::Nya::Serializable.translate_type {{@type}}
        end

        NYA_REGISTERED = true
      {% end %}
    end

    # Returns XML compatible name of an object type
    def xml_name
      self.class.xml_name
    end



    macro included
      register

      # :nodoc:
      def self.properties
        \{% if @type.superclass.has_constant? :PROPERTIES %}
          \{{@type.superclass}}.properties.merge \{{@type}}::PROPERTIES
        \{% else %}
          PROPERTIES
        \{% end %}
      end

      macro inherited
        register

        def self.deserialize(xml, ctx : SerializationContext? = nil)
          ::Nya::Serializable.debug "Deserializing \{{@type.name}}"
          ::Nya::Serializable.deserialize(xml, self, ctx)
        end
      end

      def self.deserialize(xml, ctx : SerializationContext? = nil)
        ::Nya::Serializable.deserialize(xml, self, ctx)
      end
    end

    # :nodoc:
    protected def self.parse_bool(str : String)
      case str.downcase
      when "true" || "1" || "y" || "yes"
        true
      when "false" || "0" || "n" || "no"
        false
      else
        # TODO Warn
        false
      end
    end

    # A macro to declare serializable properties
    #
    # Must be called with `TypeDeclarations`, for example:
    # `serializable foo : String, bar : Array(String), baz : Another::Serializable`
    # `serializable foobar : Array(Another::Serializable)
    #
    # The above example will be serialized to XML like following:
    #
    # ```xml
    # ... 
    # <foo>Foo content</foo>
    # <bar>
    #   <item>Bar 1</item>
    #   <item>Bar 2</item>
    #   ...
    # </bar>
    # <baz>
    #   <Another:Serializable>
    #     ...
    #   </Another:Serializable>
    # </baz>
    # <foobar>
    #   <Another:Serializable>
    #     ...
    #   </Another:Serializable>
    # </foobar>
    # ...
    # ```
    # 
    # NOTE: To serialize or deserialize a property, an object should have property 
    # accessor methods, generated with a `property` macro call or manually written.
    #
    # WARNING: Serializable class must have a default 
    # constructor, so properties must have a default value
    macro serializable(*props)
      ::Nya::Serializable.debug "R {{props}}"
      register
      {% typename = @type.stringify.gsub(/(::|[(),])/, "_").id %}
      {% for prop in props %}
        {% PROPERTIES[prop.var.stringify] = prop.type.stringify %}
        {% if prop.is_a? TypeDeclaration %}
          {% if prop.type.is_a? Path %}
            {% type = prop.type.resolve %}
            @@_deserialize_{{typename}} << Deserializator.new do |%node, %_obj|
              begin
                %obj = %_obj.as({{@type}})
                %result = %node.xpath_nodes({{prop.var.stringify}})
                %value = if %result.is_a? XML::NodeSet
                  %res = %result.first?
                  if %res.nil?
                    ""
                  else
                    %res.content
                  end
                else
                  %result.first_element_child.to_s
                end
                ::Nya::Serializable.debug "Deserializing {{prop.var}} = #{%value}"
                unless %result.nil?
                  {% if type <= String %}
                    %obj.{{prop.var}} = %value
                  {% elsif type <= Bool %}
                    %obj.{{prop.var}} = ::Nya::Serializable.parse_bool %value
                  {% elsif type <= Enum %}
                    %obj.{{prop.var}} = {{type}}.parse value
                  {% elsif type <= ::Nya::Serializable %}
                    %elem_node = if %result.is_a? XML::NodeSet
                      %result.first.first_element_child
                    else
                      %result.first_element_child
                    end
                    %obj.{{prop.var}} = {{type}}.deserialize(%elem_node.not_nil!)
                  {% else %}
                    %obj.{{prop.var}} = {{type}}.new %value unless %value.strip.empty?
                  {% end %}
                end
              rescue %e : Enumerable::EmptyError
                ::Nya::Serializable.debug "Empty!"
              end
            end

            @@_serialize_{{typename}} << Serializator.new do |%xml, %_obj|
              %obj = %_obj.as({{@type}})
              %xml.element({{prop.var.stringify}}) do
                {% if type <= ::Nya::Serializable %}
                  %obj.{{prop.var}}.serialize(%xml)
                {% else %}
                  %xml.text %obj.{{prop.var}}.to_s
                {% end %}
              end
            end
          {% elsif prop.type.is_a? Nop %}
            {% raise "Properties' types should be specified explicitly" %}
          {% elsif prop.type.is_a? Generic %}
            {% type = prop.type.name.resolve %}
            {% if type == Hash || type == Array || type == StaticArray %}
              {% type_vars = prop.type.type_vars %}
              {% key = (type == Array || type == StaticArray ? nil : type_vars.first) %}
              {% value = (type == StaticArray ? type_vars.first : type_vars.last).resolve %}

              @@_deserialize_{{typename}} << Deserializator.new do |%node, %_obj|
                %obj = %_obj.as({{@type}})
                ::Nya::Serializable.debug "Deserializing generic {{prop.var}}"


                {% if type == Array || type == StaticArray %}
                  %nodes = %node.xpath_nodes({{prop.var.stringify}} + "/item/child::*")
                  if %nodes.empty?
                    ::Nya::Serializable.debug "Empty nodes"
                    %nodes = %node.xpath_nodes({{prop.var.stringify}} + "/child::*")
                  end
                {% elsif type == Hash %}
                  %nodes = %node.xpath_nodes({{prop.var.stringify}} + "/item")
                {% end %}

                {% if type == StaticArray %}
                  %obj.{{prop.var}} = {{prop.type}}.new do |%idx|
                    %n = %nodes[%idx]
                    {% if value <= String %}
                      %n.content
                    {% elsif value <= Bool %}
                      ::Nya::Serializable.parse_bool %n.content
                    {% elsif value <= ::Nya::Serializable %}
                      {{value}}.deserialize(%n.not_nil!)
                    {% else %}
                      {{value}}.new %n.content
                    {% end %}
                  end
                {% else %}
                  %obj.{{prop.var}} = {{prop.type}}.new
                  %nodes.each do |%n|
                    %value = {% if value <= String %}
                      %n.content
                    {% elsif value <= Bool %}
                      ::Nya::Serializable.parse_bool %n.content
                    {% elsif value <= ::Nya::Serializable %}
                      {{value}}.deserialize(%n.not_nil!)
                    {% else %}
                      {{value}}.new %n.content
                    {% end %}

                    {% if type == Hash %}
                      %key = {% if key.resolve <= String %}
                        %n["key"]
                      {% else %}
                        {{key}}.new %n["key"]
                      {% end %}

                      %obj.{{prop.var}}[%key] = %value
                    {% else %}
                      %obj.{{prop.var}} << %value
                    {% end %}
                  end
                {% end %}
              end

              @@_serialize_{{typename}} << Serializator.new do |%xml, %_obj|
                %obj = %_obj.as({{@type}})
                %xml.element({{prop.var.stringify}}) do
                  %obj.{{prop.var}}.each do |{% if key %}%k, {% end %}%v|
                    %xml.element "item" {% if key %}, key: %k.to_s {% end %} do
                      {% if value <= ::Nya::Serializable %}
                        %v.serialize(%xml)
                      {% else %}
                        %xml.text %v.to_s
                      {% end %}
                    end
                  end
                end
              end
            {% else %}
              {% raise "Only hash and array are allowed generic types" %}
            {% end %}
          {% else %}
            {% raise "Cannot use #{prop.type.class} as type" %}
          {% end %}
        {% else %}
          {% raise "Properties should be in form 'name : Type'" %}
        {% end %}
      {% end %}
    end

    # A macro to declare serializable attributes
    #
    # In contrast to `serializable` macro, which declares child nodes,
    # this macro is used to declare XML attributes, so a declared 
    # attribute must be a `String`, `Bool`, `Enum`, or have a constructor
    # from `String` (like floating point or integer values)
    #
    # So, an example like this
    # ```crystal
    # class Foo
    #   include Nya::Serializable
    #   
    #   property foo = "bar", bar = SomeEnum::Value   
    #
    #   attribute foo : String, bar : SomeEnum
    # 
    #   # ... other props here
    # end
    # ```
    #
    # Will give a following output:
    # ```xml
    # <Foo foo="bar", bar="Value">
    #   ... other props here ...
    # </Foo>
    # ```
    # 
    # NOTE: Notice the `property` macro calls in the class declaration. Like
    # the `serializable` macro, `attribute` also calls property accessors.
    #
    # WARNING: As with `serializable`, serializable class must have a default 
    # constructor, so properties must have a default value
    macro attribute(*props)
      register
      {% typename = @type.stringify.gsub(/(::|[(),])/, "_").id %}
      {% for prop in props %}
        {% PROPERTIES[prop.var.stringify] = "$" + prop.type.stringify %}
        {% type = prop.type.resolve %}
        @@_serialize_attrs_{{typename}} << Serializator.new do |%xml, %_obj|
          %obj = %_obj.as({{@type}})
          %xml.attribute {{prop.var.stringify}}, %obj.{{prop.var}}.to_s
        end

        @@_deserialize_{{typename}} << Deserializator.new do |%xml, %_obj|
          %obj = %_obj.as({{@type}})
          if %xml[{{prop.var.stringify}}]?
            {% if type <= String %}
              %obj.{{prop.var}} = %xml[{{prop.var.stringify}}]
            {% elsif type <= Bool %}
              %obj.{{prop.var}} = ::Nya::Serializable.parse_bool %xml[{{prop.var.stringify}}]
            {% elsif type <= Enum %}
              %obj.{{prop.var}} = {{type}}.parse %xml[{{prop.var.stringify}}]
            {% else %}
              %obj.{{prop.var}} = {{type}}.new %xml[{{prop.var.stringify}}]
            {% end %}
          end
        end
      {% end %}
    end

    # Generates an XML shortcut for type
    macro also_known_as(name)
      ::Nya::Serializable.children[{{name.stringify}}] = ::Nya::Serializable.children[xml_name]
    end

    def serialize(xml : Builder)
      xml.element xml_name do
        serialize_attrs! xml
        serialize_props! xml
      end
    end

    def serialize
      XML.build { |xml| serialize xml }
    end

    def self.deserialize(xml : Node, type : U.class, ctx : SerializationContext? = nil) forall U
      {% unless U < ::Nya::Serializable %}
        {% raise "Cannot deserialize non-serializable type" %}
      {% end %}
      ::Nya::Serializable.debug "Deserializing XML as #{type.name}"
      name = xml.name
      if ::Nya::Serializable.children.has_key? name
        type.cast ::Nya::Serializable.children[name].call(xml, ctx)
      else
        raise Exception.new "XML type name '#{name}' is not registered"
      end
    end

    def self.deserialize(xstr : String, type : Serializable.class, ctx : SerializationContext? = nil)
      xml = XML.parse xstr
      log.debug { "Deserializing as #{type.name}" }
      deserialize xml.first_element_child.not_nil!, type, ctx
    end

  end
end
