require "pdf"

# PDF/A archival-profile layer on top of `aloli-crystal/pdf`.
#
# `pdf-a` does not re-implement PDF generation : it *configures* a
# `PDF::Document` for an ISO 19005 conformance profile and *validates*
# the structural preconditions the engine can satisfy. The underlying
# bytes are produced by `pdf`.
#
# ## Usage
#
# ```
# require "pdf-a"
#
# pdf = PDF::Document.new
# PDF::A.configure(pdf, PDF::A::Profile::A_2B) # sets pdfaid + sRGB output intent
#
# pdf.page do |page|
#   # ... draw with embedded fonts ...
# end
#
# violations = PDF::A.violations(pdf, PDF::A::Profile::A_2B)
# raise violations.map(&.message).join("\n") unless violations.empty?
# pdf.save("archival.pdf")
# ```
#
# This is milestone J3, palier 1 of the ALOLI ISO PDF trajectory.
# Scope of this first palier : the document-level preconditions
# (pdfaid identification, output intent, no encryption). Deep
# per-resource checks (every font embedded & subsetted, all colour
# spaces calibrated, no transparency groups without isolation, no
# JavaScript) are layered in subsequent paliers, and ultimately
# cross-checked by the `pdf-validate` shard (J5).

require "./pdf-a/version"
require "./pdf-a/profile"
require "./pdf-a/violation"
require "./pdf-a/conformance"
require "./pdf-a/document"
