module PDF
  module A
    # A single PDF/A conformance violation detected on a document.
    #
    # `clause` references the ISO 19005 requirement so the report is
    # traceable (the same discipline the `pdf-validate` shard will
    # generalise in J5).
    struct Violation
      getter code : Symbol
      getter message : String
      getter clause : String

      def initialize(@code : Symbol, @message : String, @clause : String)
      end

      def to_s(io : IO) : Nil
        io << "[" << @clause << "] " << @message
      end
    end
  end
end
