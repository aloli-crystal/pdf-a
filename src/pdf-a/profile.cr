module PDF
  module A
    # The PDF/A conformance profiles supported by this shard.
    #
    # * `A_2B` — ISO 19005-2 level B ("basic") : visual reproduction
    #   guaranteed, no logical-structure requirement. The pragmatic
    #   ALOLI archival target.
    # * `A_3B` — ISO 19005-3 level B : same as A-2b plus the ability
    #   to embed arbitrary files (the basis of Factur-X / ZUGFeRD).
    #
    # Level "A" (accessible) and "U" (Unicode) conformance build on
    # the Tagged PDF work (pdf J2) and are planned for later paliers.
    enum Profile
      A_2B
      A_3B

      # The PDF/A part number (XMP pdfaid:part).
      def part : Int32
        case self
        in A_2B then 2
        in A_3B then 3
        end
      end

      # The PDF/A conformance level (XMP pdfaid:conformance).
      def conformance : String
        "B"
      end

      # Human-readable name, e.g. "PDF/A-2b".
      def label : String
        "PDF/A-#{part}#{conformance.downcase}"
      end
    end
  end
end
