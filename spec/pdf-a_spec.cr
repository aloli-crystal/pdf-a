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
