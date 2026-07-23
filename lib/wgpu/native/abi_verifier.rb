# frozen_string_literal: true

module WGPU
  module Native
    class AbiVerifier
      FORCE32_KEY = "force32"
      EXTENSION_ENTRIES = {
        "SType" => %w[invalid shadersourceglsl]
      }.freeze

      def initialize(header_path: nil, native: Native)
        @header_path = header_path || self.class.default_header_path
        @native = native
      end

      def verify!
        differences = enum_differences
        return true if differences.empty?

        raise WGPU::Error, "wgpu-native ABI enum differences:\n#{differences.join("\n")}"
      end

      def enum_differences
        header_enums = parse_header
        ruby_enums.filter_map do |name, mapping|
          header_mapping = header_enums[name]
          next unless header_mapping

          compare_enum(name, ruby_mapping(mapping), header_mapping)
        end
      end

      def self.default_header_path
        override = ENV["WGPU_HEADER_PATH"]
        return File.expand_path(override) if override && !override.empty?

        candidates = Distribution.cache_directories.map do |cache_dir|
          File.join(cache_dir, "include", "webgpu", "webgpu.h")
        end
        path = candidates.find { |candidate| File.file?(candidate) }
        return path if path

        raise WGPU::Error, <<~MSG.chomp
          Pinned #{Distribution::VERSION} webgpu.h was not found.
          Run `bundle exec rake wgpu:install`, or set WGPU_HEADER_PATH.
          Searched: #{candidates.join(", ")}
        MSG
      end

      private

      def parse_header
        source = File.read(@header_path)
        source.scan(
          /typedef enum WGPU(\w+)\s*\{(.*?)\}\s*WGPU\1(?:\s+WGPU_ENUM_ATTRIBUTE)?;/m
        ).to_h do |name, body|
          entries = body.scan(
            /WGPU#{Regexp.escape(name)}_([A-Za-z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+|\d+)/
          ).to_h { |entry, value| [normalize(entry), Integer(value)] }
          entries.delete(FORCE32_KEY)
          [name, entries]
        end
      end

      def ruby_enums
        @native.constants(false).sort.filter_map do |constant_name|
          value = @native.const_get(constant_name)
          [constant_name.to_s, value.to_h] if value.is_a?(FFI::Enum)
        end
      end

      def ruby_mapping(mapping)
        mapping.to_h { |key, value| [normalize(key), value] }
      end

      def normalize(name)
        normalized = name.to_s.delete("_").downcase
        normalized.sub(/\A([123])d/, 'd\1')
      end

      def compare_enum(name, ruby_mapping, header_mapping)
        missing = header_mapping.keys - ruby_mapping.keys
        extra = ruby_mapping.keys - header_mapping.keys - EXTENSION_ENTRIES.fetch(name, [])
        wrong = (header_mapping.keys & ruby_mapping.keys).filter_map do |key|
          next if header_mapping[key] == ruby_mapping[key]

          "#{key}=#{ruby_mapping[key]} (header #{header_mapping[key]})"
        end
        return if missing.empty? && extra.empty? && wrong.empty?

        "#{name}: missing=#{missing.inspect}, extra=#{extra.inspect}, mismatched=#{wrong.inspect}"
      end
    end
  end
end
