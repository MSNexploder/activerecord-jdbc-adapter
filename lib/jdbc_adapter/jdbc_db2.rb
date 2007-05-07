module JdbcSpec
  module DB2
    module Column
      def type_cast(value)
        return nil if value.nil? || value =~ /^\s*null\s*$/i
        case type
        when :string    then value
        when :integer   then defined?(value.to_i) ? value.to_i : (value ? 1 : 0)
        when :primary_key then defined?(value.to_i) ? value.to_i : (value ? 1 : 0) 
        when :float     then value.to_f
        when :datetime  then cast_to_date_or_time(value)
        when :timestamp then cast_to_time(value)
        when :time      then cast_to_time(value)
        else value
        end
      end
      def cast_to_date_or_time(value)
        return value if value.is_a? Date
        return nil if value.blank?
        guess_date_or_time (value.is_a? Time) ? value : cast_to_time(value)
      end

      def cast_to_time(value)
        return value if value.is_a? Time
        time_array = ParseDate.parsedate value
        time_array[0] ||= 2000; time_array[1] ||= 1; time_array[2] ||= 1;
        Time.send(ActiveRecord::Base.default_timezone, *time_array) rescue nil
      end

      def guess_date_or_time(value)
        (value.hour == 0 and value.min == 0 and value.sec == 0) ?
        Date.new(value.year, value.month, value.day) : value
      end
    end
    
    def modify_types(tp)
      tp[:primary_key] = 'int generated by default as identity (start with 42) primary key'
      tp[:string][:limit] = 255
      tp[:integer][:limit] = nil
      tp[:boolean][:limit] = nil
      tp
    end
    
    def add_limit_offset!(sql, options)
      if limit = options[:limit]
        offset = options[:offset] || 0
        sql.gsub!(/SELECT/i, 'SELECT B.* FROM (SELECT A.*, row_number() over () AS internal$rownum FROM (SELECT')
        sql << ") A ) B WHERE B.internal$rownum > #{offset} AND B.internal$rownum <= #{limit + offset}"
      end
    end
    
    def quote_column_name(column_name)
      column_name
    end

    def quote(value, column = nil) # :nodoc:
      if column && column.type == :primary_key
        return value.to_s
      end
      case value
      when String                
        if column && column.type == :binary
          "BLOB('#{quote_string(value)}')"
        else
          "'#{quote_string(value)}'"
        end
      else super
      end
    end
    
    def quote_string(string)
      string.gsub(/'/, "''") # ' (for ruby-mode)
    end

    def quoted_true
      '1'
    end

    def quoted_false
      '0'
    end
  end
end
