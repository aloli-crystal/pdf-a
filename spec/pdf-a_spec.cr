require "./spec_helper"

describe PDF::A::Profile do
  it "maps A_2B to part 2 / conformance B" do
    PDF::A::Profile::A_2B.part.should eq(2)
    PDF::A::Profile::A_2B.conformance.should eq("B")
    PDF::A::Profile::A_2B.label.should eq("PDF/A-2b")
  end

  it "maps A_3B to part 3" do
    PDF::A::Profile::A_3B.part.should eq(3)
    PDF::A::Profile::A_3B.label.should eq("PDF/A-3b")
  end
end

describe PDF::A do
  describe ".configure" do
    it "sets pdfaid identification and a default sRGB output intent" do
      doc = PDF::Document.new
      PDF::A.configure(doc, PDF::A::Profile::A_2B)
      doc.pdfa_part.should eq(2)
      doc.pdfa_conformance.should eq("B")
      doc.output_intent.should_not be_nil
    end

    it "forces a file identifier so the writer emits /ID (PDF/A requires it)" do
      doc = PDF::Document.new
      doc.has_file_id?.should be_false
      PDF::A.configure(doc)
      doc.has_file_id?.should be_true
      out = doc.tap(&.page { |_| }).to_slice.map(&.chr).join
      out.should contain("/ID")
    end

    it "does not override an output intent already set" do
      doc = PDF::Document.new
      fogra = PDF::OutputIntent.fogra39
      doc.output_intent = fogra
      PDF::A.configure(doc, PDF::A::Profile::A_2B)
      doc.output_intent.should be(fogra)
    end
  end

  describe ".violations" do
    it "flags a fresh document as missing pdfaid and output intent" do
      doc = PDF::Document.new
      codes = PDF::A.violations(doc).map(&.code)
      codes.should contain(:missing_pdfaid)
      codes.should contain(:missing_output_intent)
    end

    it "returns no document-level violations after configure" do
      doc = PDF::Document.new
      PDF::A.configure(doc)
      PDF::A.violations(doc).should be_empty
      PDF::A.conformant?(doc).should be_true
    end

    it "flags encryption as forbidden" do
      doc = PDF::Document.new
      PDF::A.configure(doc)
      doc.encrypt(owner_password: "secret", level: :aes_256)
      codes = PDF::A.violations(doc).map(&.code)
      codes.should contain(:encryption_forbidden)
    end

    it "flags a part mismatch (A-3b doc validated as A-2b)" do
      doc = PDF::Document.new
      PDF::A.configure(doc, PDF::A::Profile::A_3B)
      codes = PDF::A.violations(doc, PDF::A::Profile::A_2B).map(&.code)
      codes.should contain(:wrong_pdfaid_part)
    end

    it "flags non-embedded standard-14 fonts" do
      doc = PDF::Document.new
      PDF::A.configure(doc)
      doc.page { |p| p.font "Helvetica", size: 12; p.text "x", at: {72, 700} }
      codes = PDF::A.violations(doc).map(&.code)
      codes.should contain(:non_embedded_font)
    end

    it "forbids embedded files in A-2b but allows them in A-3b" do
      doc = PDF::Document.new
      PDF::A.configure(doc, PDF::A::Profile::A_3B)
      doc.attach_file(
        name: "data.xml",
        bytes: "<x/>".to_slice,
        mime_type: "application/xml",
      )

      # As A-2b → forbidden.
      PDF::A.violations(doc, PDF::A::Profile::A_2B).map(&.code)
        .should contain(:embedded_files_forbidden)
      # As A-3b → allowed (the embedded-file rule does not fire).
      PDF::A.violations(doc, PDF::A::Profile::A_3B).map(&.code)
        .should_not contain(:embedded_files_forbidden)
    end
  end

  describe "PDF::A::Document" do
    it "auto-configures pdfaid + output intent on construction" do
      doc = PDF::A::Document.new(PDF::A::Profile::A_2B)
      doc.pdfa_part.should eq(2)
      doc.output_intent.should_not be_nil
      doc.profile.should eq(PDF::A::Profile::A_2B)
    end

    it "raises ConformanceError on save when a violation remains (strict)" do
      doc = PDF::A::Document.new
      # Use a non-embedded standard font → violation at write time.
      doc.page { |p| p.font "Helvetica", size: 12; p.text "x", at: {72, 700} }
      expect_raises(PDF::A::ConformanceError, /non-embedded|Helvetica|6\.3\.4/i) do
        doc.to_slice
      end
    end

    it "does not raise in non-strict mode" do
      doc = PDF::A::Document.new(PDF::A::Profile::A_2B, strict: false)
      doc.page { |p| p.font "Helvetica", size: 12; p.text "x", at: {72, 700} }
      bytes = doc.to_slice
      bytes.size.should be > 0
    end

    it "writes successfully when conformant (embedded font, no violations)" do
      doc = PDF::A::Document.new
      font = doc.load_font("#{__DIR__}/fixtures/DejaVuSans.ttf") if File.exists?("#{__DIR__}/fixtures/DejaVuSans.ttf")
      if font
        doc.page do |p|
          p.font font, size: 12
          p.text "Archive", at: {72, 700}
        end
        out = doc.to_slice.map(&.chr).join
        out.should contain("<pdfaid:part>2</pdfaid:part>")
      else
        # No embedded font fixture available → at least confirm an
        # empty (font-free) page conforms.
        doc.page { |_| }
        doc.to_slice.size.should be > 0
      end
    end
  end

  describe "end to end" do
    it "produces a document whose XMP carries the pdfaid marker" do
      doc = PDF::Document.new
      PDF::A.configure(doc, PDF::A::Profile::A_2B)
      doc.page { |p| p.font "Helvetica", size: 12; p.text "Archive", at: {72, 700} }

      out = doc.to_slice.map(&.chr).join
      out.should contain("<pdfaid:part>2</pdfaid:part>")
      out.should contain("<pdfaid:conformance>B</pdfaid:conformance>")
      out.should contain("/OutputIntents")
    end
  end
end
