module Gedcom
  class Importer
    attr_reader :stats

    # Mapping of GEDCOM CHAR tag values to Ruby encoding names
    ENCODING_MAP = {
      "UTF-8"    => "UTF-8",
      "UNICODE"  => "UTF-8",
      "ANSEL"    => "UTF-8",       # Best-effort; true ANSEL is rare in modern files
      "ASCII"    => "US-ASCII",
      "ANSI"     => "Windows-1252", # Western ANSI default
      "IBMPC"    => "IBM437",
    }.freeze

    # Common encodings for Arabic text, tried in order as fallbacks
    ARABIC_FALLBACK_ENCODINGS = %w[
      UTF-8
      Windows-1256
      ISO-8859-6
      Windows-1252
      ISO-8859-1
    ].freeze

    def initialize(file_content)
      @raw = normalize_encoding(file_content)
      @lines = @raw.lines.map(&:strip).reject(&:empty?)
      @people_map = {}   # gedcom_id => Person
      @families_map = {} # gedcom_id => Family
      @stats = { people: 0, families: 0 }
    end

    def import!
      records = parse_lines_to_records
      ActiveRecord::Base.transaction do
        import_individuals(records.select { |r| r[:tag] == "INDI" })
        import_families(records.select { |r| r[:tag] == "FAM" })
      end
      @stats
    end

    private

    # Detect and convert file content to UTF-8, preserving Arabic and other non-Latin scripts
    def normalize_encoding(content)
      # Force binary so we can inspect raw bytes
      raw = content.dup.force_encoding("ASCII-8BIT")

      # Strip BOM (Byte Order Mark) and detect UTF-16
      raw, detected = strip_bom(raw)

      # If BOM told us it's UTF-16, convert and return
      if detected
        return raw.encode("UTF-8", detected, invalid: :replace, undef: :replace, replace: "\uFFFD")
      end

      # Already valid UTF-8? Return immediately.
      if valid_encoding?(raw, "UTF-8")
        return raw.force_encoding("UTF-8")
      end

      # Try the encoding declared in the GEDCOM CHAR header
      declared = detect_char_from_header(raw)
      if declared
        ruby_enc = ENCODING_MAP[declared.upcase] || declared

        # "ANSI" is ambiguous — could be Windows-1252 (Western) or Windows-1256 (Arabic).
        # Try Windows-1256 first if high bytes are present (likely Arabic content).
        if declared.upcase == "ANSI" && contains_high_bytes?(raw)
          candidate = try_encode(raw, "Windows-1256")
          return candidate if candidate && contains_arabic?(candidate)
        end

        if valid_encoding?(raw, ruby_enc)
          return raw.force_encoding(ruby_enc).encode("UTF-8")
        end
      end

      # Try each Arabic fallback encoding until one produces valid UTF-8
      ARABIC_FALLBACK_ENCODINGS.each do |enc|
        if valid_encoding?(raw, enc)
          result = raw.force_encoding(enc).encode("UTF-8", invalid: :replace, undef: :replace, replace: "\uFFFD")
          # Check the result doesn't have excessive replacement characters (sanity check)
          replacement_ratio = result.count("\uFFFD").to_f / [result.length, 1].max
          return result if replacement_ratio < 0.1
        end
      end

      # Last resort: force UTF-8 with replacement
      raw.force_encoding("UTF-8")
         .encode("UTF-8", invalid: :replace, undef: :replace, replace: "\uFFFD")
    end

    # Strip UTF-8/UTF-16 BOM and return [stripped_content, detected_encoding_or_nil]
    def strip_bom(raw)
      bom_utf8    = "\xEF\xBB\xBF".b
      bom_utf16le = "\xFF\xFE".b
      bom_utf16be = "\xFE\xFF".b

      if raw.start_with?(bom_utf8)
        [raw[3..], "UTF-8"]
      elsif raw.start_with?(bom_utf16le)
        [raw[2..], "UTF-16LE"]
      elsif raw.start_with?(bom_utf16be)
        [raw[2..], "UTF-16BE"]
      else
        [raw, nil]
      end
    end

    # Check if raw bytes are valid when interpreted as the given encoding
    def valid_encoding?(raw, encoding_name)
      raw.dup.force_encoding(encoding_name).valid_encoding?
    rescue ArgumentError
      false
    end

    # Scan the first few lines for "1 CHAR <encoding>" in the HEAD record
    def detect_char_from_header(raw)
      # Read the first 2KB to find the CHAR tag (always near the top)
      header_chunk = raw[0, 2048] || raw
      header_chunk.force_encoding("ASCII-8BIT")

      header_chunk.each_line do |line|
        stripped = line.strip
        # Stop scanning after HEAD record ends
        break if stripped =~ /\A0\s+@/ || (stripped =~ /\A0\s+/ && stripped !~ /\A0\s+HEAD/)
        if stripped =~ /\A1\s+CHAR\s+(.+)/i
          return $1.strip
        end
      end

      nil
    end

    # Check if raw bytes contain values > 127 (non-ASCII, likely Arabic or other multibyte)
    def contains_high_bytes?(raw)
      raw.each_byte.any? { |b| b > 127 }
    end

    # Attempt to encode raw bytes from source_enc to UTF-8, returns nil on failure
    def try_encode(raw, source_enc)
      raw.dup.force_encoding(source_enc).encode("UTF-8")
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      nil
    end

    # Check if a UTF-8 string contains Arabic Unicode characters (U+0600–U+06FF)
    def contains_arabic?(str)
      str.match?(/[\u0600-\u06FF]/)
    end

    # Parse GEDCOM lines into a flat array of record hashes with nested sub-records
    def parse_lines_to_records
      records = []
      current_record = nil
      stack = []

      @lines.each do |line|
        level, xref_or_tag, value = parse_line(line)
        next unless level

        if level == 0
          records << current_record if current_record
          if xref_or_tag&.start_with?("@")
            current_record = { xref: xref_or_tag, tag: value, subs: [] }
          else
            current_record = { xref: nil, tag: xref_or_tag, subs: [] }
          end
          stack = [current_record]
        elsif current_record
          node = { tag: xref_or_tag, value: value, subs: [] }
          # Find parent at level - 1
          parent = stack[level - 1]
          parent[:subs] << node if parent
          stack[level] = node
        end
      end

      records << current_record if current_record
      records.compact
    end

    def parse_line(line)
      parts = line.split(" ", 3)
      return nil if parts.empty?

      level = parts[0].to_i
      second = parts[1]
      third = parts[2]

      if second&.start_with?("@") && third
        # Level 0: "0 @I001@ INDI"
        [level, second, third]
      else
        [level, second, third]
      end
    end

    def import_individuals(records)
      records.each do |record|
        attrs = extract_person_attrs(record)
        person = Person.create!(attrs.merge(gedcom_id: record[:xref]))
        @people_map[record[:xref]] = person
        @stats[:people] += 1
      end
    end

    def extract_person_attrs(record)
      attrs = { first_name: "Unknown" }

      record[:subs].each do |sub|
        case sub[:tag]
        when "NAME"
          name_parts = parse_gedcom_name(sub[:value])
          attrs[:first_name] = name_parts[:first] if name_parts[:first].present?
          attrs[:last_name] = name_parts[:last] if name_parts[:last].present?
        when "SEX"
          attrs[:gender] = case sub[:value]&.strip&.upcase
                           when "M" then :male
                           when "F" then :female
                           else :unknown
                           end
        when "BIRT"
          sub[:subs].each do |s|
            attrs[:birth_date] = parse_gedcom_date(s[:value]) if s[:tag] == "DATE"
            attrs[:birth_place] = s[:value]&.strip if s[:tag] == "PLAC"
          end
        when "DEAT"
          sub[:subs].each do |s|
            attrs[:death_date] = parse_gedcom_date(s[:value]) if s[:tag] == "DATE"
            attrs[:death_place] = s[:value]&.strip if s[:tag] == "PLAC"
          end
        when "NOTE"
          attrs[:notes] = sub[:value]&.strip
        end
      end

      attrs
    end

    # Parse "John William /Smith/" → { first: "John William", last: "Smith" }
    def parse_gedcom_name(name_str)
      return { first: "Unknown", last: nil } if name_str.blank?
      if name_str =~ %r{^(.*?)\s*/([^/]*)/\s*$}
        { first: $1.strip.presence || "Unknown", last: $2.strip.presence }
      else
        { first: name_str.strip, last: nil }
      end
    end

    def parse_gedcom_date(date_str)
      return nil if date_str.blank?
      # Strip qualifiers like ABT, BEF, AFT, EST
      cleaned = date_str.strip.sub(/\A(ABT|BEF|AFT|EST|CAL|FROM|TO|BET)\s+/i, "")
      cleaned = cleaned.sub(/\s+AND\s+.*/i, "") # Handle "BET X AND Y"

      begin
        Date.parse(cleaned)
      rescue Date::Error
        # Try year-only
        if cleaned =~ /\A(\d{4})\z/
          Date.new($1.to_i, 1, 1)
        else
          nil
        end
      end
    end

    def import_families(records)
      records.each do |record|
        family_attrs = {}
        husb_ref = nil
        wife_ref = nil
        child_refs = []

        record[:subs].each do |sub|
          case sub[:tag]
          when "HUSB" then husb_ref = sub[:value]&.strip
          when "WIFE" then wife_ref = sub[:value]&.strip
          when "CHIL" then child_refs << sub[:value]&.strip
          when "MARR"
            sub[:subs].each do |s|
              family_attrs[:marriage_date] = parse_gedcom_date(s[:value]) if s[:tag] == "DATE"
              family_attrs[:marriage_place] = s[:value]&.strip if s[:tag] == "PLAC"
            end
          end
        end

        family = Family.create!(family_attrs.merge(gedcom_id: record[:xref]))
        @families_map[record[:xref]] = family

        if husb_ref && @people_map[husb_ref]
          FamilyMember.create!(person: @people_map[husb_ref], family: family, role: :father)
        end
        if wife_ref && @people_map[wife_ref]
          FamilyMember.create!(person: @people_map[wife_ref], family: family, role: :mother)
        end
        child_refs.each do |ref|
          FamilyMember.create!(person: @people_map[ref], family: family, role: :child) if @people_map[ref]
        end

        @stats[:families] += 1
      end
    end
  end
end
