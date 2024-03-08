module Nya::Serializable
  class Exception < ::Exception
    property field_name : String

    def initialize(@field_name, message : String? = nil, cause : ::Exception? = nil)
      super message, cause
    end
  end
end