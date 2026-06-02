module PDF
  module A
    # Configures a `PDF::Document` for a PDF/A profile and validates
    # the document-level preconditions the engine can satisfy.

    # Configures `doc` for `profile` :
    # * sets the XMP pdfaid identification (`pdfaid:part` /
    #   `pdfaid:conformance`),
    # * ensures an output intent is present (defaults to the bundled
    #   sRGB v4 ICC profile if none was set).
    #
    # Returns `doc` for chaining. Call this *before* `save`.
    def self.configure(doc : PDF::Document, profile : Profile = Profile::A_2B) : PDF::Document
      doc.pdfa_part = profile.part
      doc.pdfa_conformance = profile.conformance
      doc.output_intent ||= PDF::OutputIntent.srgb
      doc
    end

    # Returns the list of detected PDF/A violations for `profile`.
    # An empty array means the document passes the *document-level*
    # checks this palier implements — it does NOT yet certify full
    # ISO 19005 conformance (per-resource checks come later, and the
    # authoritative verdict is the job of `pdf-validate` in J5).
    def self.violations(doc : PDF::Document, profile : Profile = Profile::A_2B) : Array(Violation)
      list = [] of Violation

      # --- pdfaid identification (ISO 19005-2 § 6.7.11) ---
      if doc.pdfa_part.nil? || doc.pdfa_conformance.nil?
        list << Violation.new(
          :missing_pdfaid,
          "Missing PDF/A identification (XMP pdfaid). Call PDF::A.configure(doc, #{profile}).",
          "ISO 19005-2 § 6.7.11",
        )
      else
        if doc.pdfa_part != profile.part
          list << Violation.new(
            :wrong_pdfaid_part,
            "XMP pdfaid:part is #{doc.pdfa_part}, expected #{profile.part} for #{profile.label}.",
            "ISO 19005-2 § 6.7.11",
          )
        end
      end

      # --- Output intent (ISO 19005-2 § 6.2.2) ---
      if doc.output_intent.nil?
        list << Violation.new(
          :missing_output_intent,
          "A PDF/A file must declare an OutputIntent with an embedded ICC profile.",
          "ISO 19005-2 § 6.2.2",
        )
      end

      # --- Encryption forbidden (ISO 19005-2 § 6.1.3) ---
      unless doc.security_handler.nil? && doc.encryption.nil?
        list << Violation.new(
          :encryption_forbidden,
          "Encryption is forbidden in PDF/A.",
          "ISO 19005-2 § 6.1.3",
        )
      end

      list
    end

    # `true` if `doc` passes the document-level checks for `profile`.
    def self.conformant?(doc : PDF::Document, profile : Profile = Profile::A_2B) : Bool
      violations(doc, profile).empty?
    end
  end
end
