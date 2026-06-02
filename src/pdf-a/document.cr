module PDF
  module A
    # A `PDF::Document` pre-configured for a PDF/A profile that
    # validates itself before writing.
    #
    # On construction it runs `PDF::A.configure` (sets the pdfaid
    # identification and a default sRGB output intent). On `write`
    # (and therefore `save`) it runs `PDF::A.violations` ; in the
    # default *strict* mode it raises `ConformanceError` if any
    # document-level violation remains, so a non-conforming archive
    # never reaches disk silently.
    #
    # ```
    # pdf = PDF::A::Document.new(PDF::A::Profile::A_2B)
    # pdf.page do |page|
    #   font = pdf.load_font("DejaVuSans.ttf") # embedded → conformant
    #   page.font font, size: 12
    #   page.text "Archive", at: {72, 700}
    # end
    # pdf.save("archive.pdf") # raises if any PDF/A violation remains
    # ```
    #
    # Set `strict: false` to collect violations without raising
    # (inspect them via `PDF::A.violations(doc)` yourself).
    class Document < PDF::Document
      getter profile : Profile
      property? strict : Bool

      def initialize(@profile : Profile = Profile::A_2B, @strict : Bool = true)
        super()
        PDF::A.configure(self, @profile)
      end

      # Validates the document against its profile, then writes it.
      # In strict mode, raises `ConformanceError` if any violation
      # remains.
      def write(io : IO) : Nil
        violations = PDF::A.violations(self, @profile)
        if @strict && !violations.empty?
          raise ConformanceError.new(@profile, violations)
        end
        super(io)
      end
    end

    # Raised by `PDF::A::Document#write` in strict mode when the
    # document fails its PDF/A profile checks.
    class ConformanceError < Exception
      getter profile : Profile
      getter violations : Array(Violation)

      def initialize(@profile : Profile, @violations : Array(Violation))
        super(build_message)
      end

      private def build_message : String
        String.build do |io|
          io << @profile.label << " conformance failed (" << @violations.size
          io << " violation(s)):\n"
          @violations.each { |v| io << "  - " << v.to_s << "\n" }
        end
      end
    end
  end
end
