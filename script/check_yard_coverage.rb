# frozen_string_literal: true

require "yard"

YARD::Registry.clear
YARD.parse(
  [
    "lib/**/*.{rb,rbs}",
    "sig/**/*.rbs",
    "ext/**/*.{c,cc,cxx,cpp,rb}"
  ]
)

undocumented_methods = YARD::Registry.all(:method).select do |object|
  object.visibility == :public &&
    !object.is_alias? &&
    !object.is_attribute? &&
    !object.tag(:private) &&
    !(object.namespace.respond_to?(:tag) && object.namespace.tag(:private)) &&
    object.docstring.blank?
end

if undocumented_methods.empty?
  puts "YARD coverage: all public methods are documented"
  exit
end

warn "Undocumented public methods:"
undocumented_methods.sort_by(&:path).each do |object|
  warn "  #{object.path} (#{object.file}:#{object.line})"
end
exit 1
