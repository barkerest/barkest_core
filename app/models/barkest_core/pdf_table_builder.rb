module BarkestCore

  ##
  # A table builder to ease creation of tables in PDF documents.
  #
  class PdfTableBuilder

    ##
    # Creates a new table builder in the provided +document+.
    #
    # The options can specify both table options and :cell_style options.
    # The :cell_style option should be a hash of styles for the cells in your table.
    #
    def initialize(document, options = {}, &block)
      options ||= {}

      @doc = document

      @data = []
      @col_offset = 0
      @row_offset = 0
      @col_start = 0

      @base_cell_options = { borders: [] }.merge(options[:cell_style] || { })
      @options = options.except(:cell_style)

      yield self if block_given?
    end

    ##
    # Gets the cell options provided during the TableBuilder creation.
    def base_cell_options
      @base_cell_options
    end

    ##
    # Gets the table options provided during the TableBuilder creation.
    def table_options
      @options
    end

    ##
    # Generates the table array used by Prawn::Table.
    def to_table
      @doc.make_table(data, table_options)
    end

    ##
    # Gets the current position in the table.
    def position
      [ @row_offset, @col_offset ]
    end

    ##
    # Gets the current row in the table.
    def current_row
      @row_offset
    end

    ##
    # Gets the current column in the table.
    def current_column
      @col_offset
    end

    ##
    # Gets the last row in the table.
    def last_row
      @data.length - 1
    end

    ##
    # Gets the last column in the table.
    def last_column
      max = 0
      @data.each do |row|
        max = row.length if max < row.length
      end
      max - 1
    end

    ##
    # Builds data starting at the specified column.
    #
    # The +start_column+ is the first column you want to be building.
    # When you start a new row inside of a build_column block, the new row
    # starts at this same column.
    def build_column(start_column = nil)
      if block_given?
        raise StandardError.new('build_column block called within row block') if @in_row
        raise StandardError.new('build_column called without valid argument') unless start_column.is_a?(Numeric)

        backup_col_start = @col_start
        backup_col_offset = @col_offset
        backup_row_offset = @row_offset
        @col_start = start_column.to_i
        @col_offset = @col_start
        @row_offset = 0

        yield

        @col_start = backup_col_start
        @col_offset = backup_col_offset
        @row_offset = backup_row_offset
      end
      @col_start
    end

    ##
    # Builds a row in the table.
    #
    # Valid options:
    #
    # row::
    #   Defines the row you want to start on.  If not set, then it uses #current_row.
    #
    # Additional options are merged with the base cell options for this row.
    #
    # When it completes, the #current_row is set to 1 more than the row we started on.
    #
    def row(options = {}, &block)
      raise StandardError.new('row called within row block') if @in_row

      @in_row = true
      @col_offset = @col_start
      options = change_row(options || {})

      @row_cell_options = @base_cell_options.merge(options)

      fill_cells(@row_offset, @col_offset)

      # skip placeholders when starting a new row.
      if @data[@row_offset]
        while @data[@row_offset][@col_offset] == :span_placeholder
          @col_offset += 1
        end
      end

      yield if block_given?

      @in_row = false
      @row_offset += 1
      @row_cell_options = nil
    end

    ##
    # Builds a subtable within the current row.
    #
    # The +cell_options+ are passed to the current cell.
    # The +options+ are passed to the new TableBuilder.
    #
    def subtable(cell_options = {}, options = {}, &block)
      raise StandardError.new('subtable called outside of row block') unless @in_row
      cell cell_options || {} do
        PdfTableBuilder.new(@doc, options || {}, &block).to_table
      end
    end

    ##
    # Creates a bold cell.
    #
    # See #cell for valid options.
    #
    def bold_cell(options = {}, &block)
      cell({ font_style: :bold }.merge(options || {}), &block)
    end

    ##
    # Creates an italicized cell.
    #
    # See #cell for valid options.
    #
    def italic_cell(options = {}, &block)
      cell({ font_style: :italic }.merge(options || {}), &block)
    end

    ##
    # Creates a bold-italic cell.
    #
    # See #cell for valid options.
    #
    def bold_italic_cell(options = {}, &block)
      cell({ font_style: :bold_italic }.merge(options || {}), &block)
    end

    ##
    # Creates an underlined cell.
    #
    # See #cell for valid options.
    #
    def underline_cell(options = {}, &block)
      cell({ borders: [ :bottom ], border_width: 0.5 }.merge(options || {}), &block)
    end

    ##
    # Creates multiple cells.
    #
    # Individual cells can be given options by prefixing the keys with 'cell_#' where # is the cell number (starting at 1).
    #
    # See #cell for valid options.
    #
    def cells(options = {}, &block)
      cell_regex = /^cell_([0-9]+)_/

      options ||= { }

      result = block_given? ? yield : (options[:values] || [''])

      cell_options = result.map { {} }
      common_options = {}

      options.each do |k,v|
        # if the option starts with 'cell_#_' then apply it accordingly.
        if (m = cell_regex.match(k.to_s))
          k = k.to_s[m[0].length..-1].to_sym
          cell_options[m[1].to_i - 1][k] = v

        # the 'column' option applies only to the first cell.
        elsif k == :column
          cell_options[0][k] = v

        # everything else applies to all cells, unless overridden explicitly.
        elsif k != :values
          common_options[k] = v
        end
      end

      cell_options.each_with_index do |opt,idx|
        cell common_options.merge(opt).merge( { value: result[idx] } )
      end
    end

    ##
    # Creates a pair of cells.
    # The first cell is bold with the :key option and the second cell is normal with the :value option.
    #
    # Additional options can be specified as they are in #cells.
    #
    def key_value(options = {}, &block)
      options ||= {}

      if options[:key]
        options[:values] ||= []
        options[:values][0] = options[:key]
      end
      if options[:value]
        options[:values] ||= []
        options[:values][1] = options[:value]
      end

      options = {
          cell_1_font_style: :bold
      }.merge(options.except(:key, :value))

      cells options, &block
    end

    ##
    # Generates a cell in the current row.
    #
    # Valid options:
    #
    # value::
    #   The value to put in the cell, unless a code block is provided, in which case the result of the code block is used.
    #
    # rowspan::
    #   The number of rows for this cell to cover.
    #
    # colspan::
    #   The number of columns for this cell to cover.
    #
    # Additional options are embedded and passed on to Prawn::Table, see {Prawn PDF Table Manual}[http://prawnpdf.org/prawn-table-manual.pdf] for more information.
    #
    def cell(options = {}, &block)
      raise StandardError.new('cell called outside of row block') unless @in_row

      options = @row_cell_options.merge(options || {})

      options = change_col(options)

      result = block_given? ? yield : (options[:value] || '')

      options.except!(:value)

      set_cell(result, nil, nil, options)
    end


    private

    def data
      fix_row_widths
      # remove all placeholders.
      ret = @data.map do |row|
        row.delete_if { |item| item == :span_placeholder }
      end
      # remove all empty rows.
      ret.delete_if { |row| row.empty? }
    end

    def change_row(options)
      if options[:row] && options[:row] >= 0
        @row_offset = options[:row]
      end
      options.except(:row)
    end

    def change_col(options)
      if options[:column] && options[:column] >= 0
        @col_offset = @col_start + options[:column]
      end
      options.except(:column)
    end

    def fill_cells(row, col)
      return unless row >= 0 && col >= 0

      if @data.length <= row
        @data += [[ (@row_cell_options || @base_cell_options).merge({content: ''}) ]] * (row - @data.length + 1)
      end

      if @data[row].length <= col
        @data[row] += [ (@row_cell_options || @base_cell_options).merge({content: ''}) ] * (col - @data[row].length + 1)
      end
    end

    def clear_cell(row, col)
      fill_cells row, col

      unless @data[row][col].blank?
        raise StandardError.new('placeholders cannot be cleared') if @data[row][col] == :span_placeholder

        if @data[row][col].is_a? Hash
          options = @data[row][col][:options] || { }
          rspan = options[:rowspan] || 1
          cspan = options[:colspan] || 1

          # clear all the cells covered by the previous value.
          (0...rspan).each do |r|
            (0...cspan).each do |c|
              @data[row + r][col + c] = ''
            end
          end

        else
          @data[row][col] = ''
        end
      end
    end

    def set_cell(val, set_row = nil, set_col = nil, options = {})
      row = set_row || @row_offset
      col = set_col || @col_offset

      clear_cell row, col

      if options.empty?
        @data[row][col] = val
      else
        @data[row][col] = options.merge({ content: val })
      end

      rspan = options[:rowspan] || 1
      cspan = options[:colspan] || 1

      # fill in placeholders for the spans.
      (1...cspan).each do |c|
        set_cell(:span_placeholder, row, col + c)
      end
      (1...rspan).each do |r|
        (0...cspan).each do |c|
          set_cell(:span_placeholder, row + r, col + c)
        end
      end

      unless set_col
        @col_offset += 1
        # skip over placeholders to set the next column position.
        while @data[row][@col_offset] == :span_placeholder
          @col_offset += 1
        end
      end
    end

    # ensure that all 2nd level arrays are the same size.
    def fix_row_widths

      fill_cells(@row_offset - 1, 0)

      max = 0

      @data.each_with_index do |row|
        max = row.length unless max >= row.length
      end

      @data.each_with_index do |row,idx|
        if row.length < max
          row = row + [ @base_cell_options.merge({content: ''}) ] * (max - row.length)
          @data[idx] = row
        end
      end

    end

  end
end
