require 'axlsx'
require 'axlsx_rails'

# :nodoc:
module Axlsx

  ##
  # The Package class is used to manage the Excel file in memory.
  class Package

    ##
    # Creates a simple workbook with one sheet.
    #
    # Predefines multiple styles that can be used to format cells.
    # The +sheet+ and +styles+ are yielded to the provided block.
    #
    # See Axlsx::Workbook#predefined_styles for a list of predefined styles.
    #
    def simple(name = nil)
      workbook.add_worksheet(name: name || 'Sheet 1') do |sheet|
        yield sheet, workbook.predefined_styles if block_given?
        sheet.add_row
      end
    end

    alias :barkest_core_original_workbook :workbook

    # :nodoc:
    def workbook
      @workbook ||= Workbook.new
      @workbook.package = self
      yield @workbook if block_given?
      @workbook
    end

  end

  ##
  # The Workbook class is used to manage the Excel file in memory.
  class Workbook

    attr_accessor :package

    ##
    # Gets the predefined style list.
    #
    # The +predefined_styles+ hash contains :bold, :date, :float, :integer, :percent, :currency, :text, :wrapped, and :normal
    # styles for you to use.
    #
    def predefined_styles
      @predefined_styles ||=
          begin
            tmp = {}
            styles do |s|
              tmp = {
                  bold:       s.add_style(b: true, alignment: { vertical: :top }),
                  date:       s.add_style(format_code: 'mm/dd/yyyy', alignment: { vertical: :top }),
                  float:      s.add_style(format_code: '#,##0.00', alignment: { vertical: :top }),
                  integer:    s.add_style(format_code: '#,##0', alignment: { vertical: :top }),
                  percent:    s.add_style(num_fmt: 9, alignment: { vertical: :top }),
                  currency:   s.add_style(num_fmt: 7, alignment: { vertical: :top }),
                  text:       s.add_style(format_code: '@', alignment: { vertical: :top }),
                  wrapped:    s.add_style(alignment: { wrap_text: true, vertical: :top }),
                  normal:     s.add_style(alignment: { vertical: :top })
              }
            end
            tmp
          end
    end
  end


  # :nodoc:
  class Cell

    alias :barkest_core_original_cast_value :cast_value

    # Fix the conversion of Date/Time values.
    # :nodoc:
    def cast_value(v)
      return nil if v.nil?
      if @type == :date
        self.style = STYLE_DATE if self.style == 0
        v
      elsif (@type == :time && v.is_a?(Time)) || (@type == :time && v.respond_to?(:to_time))
        self.style = STYLE_DATE if self.style == 0
        # one simple little fix.  I DO NOT WANT TIME IN LOCAL TIME!
        unless v.is_a?(Time)
          v = v.respond_to?(:to_time) ? v.to_time : v
        end
        v
      elsif @type == :float
        v.to_f
      elsif @type == :integer
        v.to_i
      elsif @type == :boolean
        v ? 1 : 0
      elsif @type == :iso_8601
        #consumer is responsible for ensuring the iso_8601 format when specifying this type
        v
      else
        @type = :string
        # TODO find a better way to do this as it accounts for 30% of
        # processing time in benchmarking...
        Axlsx::trust_input ? v.to_s : ::CGI.escapeHTML(v.to_s)
      end
    end
  end

  ##
  # The Worksheet class is used to manage the Excel file in memory.
  class Worksheet

    ##
    # Adds a row to the worksheet with combined data.
    #
    # Currently we support specifying the +values+, +styles+, and +types+ using this method.
    #
    # The +row_data+ value should be an array of arrays.
    # Each subarray represents a value in the row with up to three values specifying the +value+, +style+, and +type+.
    # Value is the only item required.
    #   [['Value 1', :bold, :string], ['Value 2'], ['Value 3', nil, :string]]
    #
    # In fact, if a subarray is replaced by a value, it is treated the same as an array only containing that value.
    #   [['Value 1', :bold, :string], 'Value 2', ['Value 3', nil, :string]]
    #
    # The +keys+ parameter defines the location of the data elements within the sub arrays.
    # The default would be [ :value, :style, :type ].  If your array happens to have additional data or data arranged
    # in a different format, you can set this to anything you like to get the method to process your data
    # appropriately.
    #   keys = [ :ignored, :value, :ignored, :ignored, :style, :ignored, :type ]
    #
    # Styles can be specified as a symbol to use the predefined styles, or as a style object you created.
    #
    def add_combined_row(row_data, keys = [ :value, :style, :type ])
      val_index = keys.index(:value) || keys.index('value')
      style_index = keys.index(:style) || keys.index('style')
      type_index = keys.index(:type) || keys.index('type')

      raise ArgumentError.new('Missing :value key') unless val_index
      values = row_data.map{|v| v.is_a?(Array) ? v[val_index] : v }
      styles = style_index ? row_data.map{ |v| v.is_a?(Array) ? v[style_index] : nil } : []
      types = type_index ? row_data.map{ |v| v.is_a?(Array) ? v[type_index] : nil } : []

      # allows specifying the style as just a symbol.
      styles.each_with_index do |style,index|
        if style.is_a?(String) || style.is_a?(Symbol)
          styles[index] = workbook.predefined_styles[style.to_sym]
        end
      end

      add_row values, style: styles, types: types
    end

  end

end