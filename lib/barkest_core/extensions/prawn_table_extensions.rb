require 'prawn'
require 'prawn/table'

##
# Improvements made to the Prawn::Table::Interface module.
module Prawn::Table::Interface
  private

  # process and remove custom table options.
  def preprocess_table_options(options)

    # get the maximum width.
    max_width = bounds.right - bounds.left

    # allow column and table widths to be specified as ratios.
    { column_ratios: :column_widths, width_ratio: :width }.each do |k,v|
      if options[k]
        # extract the option.
        ratio = options[k]
        options.except!(k)

        if ratio.is_a?(Array)
          options[v] = ratio.map { |r| (r > 1 ? r/100.0 : r).to_f * max_width }
        elsif ratio.respond_to?(:to_f)
          options[v] = (ratio > 1 ? ratio/100.0 : ratio).to_f * max_width
        end
      end
    end

    options
  end

  # process the table data and verify all values are strings.
  def preprocess_table_data(data)
    # recurse into arrays.
    if data.is_a?(Array)
      data = data.map { |item| preprocess_table_data(item) }

      # verify the hash :content value is a string.
    elsif data.is_a?(Hash)
      data[:content] = preprocess_table_data(data[:content])

      # symbols should resolve to methods on the attached object.
      # we filter it through the preprocess function again just to make sure it's good.
    elsif data.is_a?(Symbol)
      data = preprocess_table_data(object_field_value(data))

      # Nil, True, False, Date, Time, and Numeric values should be converted to strings.
    elsif data.nil? || data.is_a?(Numeric) || data.is_a?(Date) || data.is_a?(Time) || data.is_a?(TrueClass) || data.is_a?(FalseClass)
      data = data.to_s
    end

    data
  end

  public

  alias :barkest_core_original_table :table

  ##
  # An overridden version of the table method allowing for more powerful options and dynamic data.
  #
  # The +data+ gains the ability to receive values from a linked object.  Much like form helpers, if you
  # specify :name for a cell value, and there is a linked object, the linked object will be searched for a :name
  # attribute.  If that exists, then the value of the attribute is used, otherwise the symbol is converted to a
  # string and that value is used.
  #
  # The +options+ hash gains :column_ratios and :width_ratio keys that automatically set the :column_widths and
  # :width keys based on the current bounding box.
  #
  #   { :column_rations => [ 5, 25, 10, 10 ], :width_ratio => 50 }
  #
  # A potential weakness would be that the :column_ratios are a percentage of the maximum width, not the table
  # width.  In the example above, the table is 50% of the maximum width and the column widths add up to 50%.
  #
  # After the table is constructed, it is rendered to the PDF.
  #
  def table(data, options = {}, &block)
    options = preprocess_table_options(options)
    data = preprocess_table_data(data)

    t = Prawn::Table.new(data, self, options, &block)
    t.draw
    t
  end

  alias :barkest_core_original_make_table :make_table

  ##
  # This is the same as #table except the table is not rendered after construction.
  #
  def make_table(data, options = {}, &block)
    options = preprocess_table_options(options)
    data = preprocess_table_data(data)

    Prawn::Table.new(data, self, options, &block)
  end

  ##
  # Uses a TableBuilder to construct a table and then renders the results to the PDF.
  #
  def table_builder(options = {}, &block)
    t = BarkestCore::PdfTableBuilder.new(self, options, &block).to_table
    t.draw
    t
  end

  ##
  # Generates an array containing a label cell and a value cell.
  #
  # The label cell has a bold font, the value cell does not.
  # Both cells inherit the shared_attribs.
  #
  def table_pair(label, value, shared_attribs = {})
    bold_label = ({ bold_label: true }.merge(shared_attribs))[:bold_label]
    shared_attribs.except!(:bold_label)

    label = preprocess_table_data(label)
    value = preprocess_table_data(value)

    label = shared_attribs.merge(label.is_a?(Hash) ? label : { content: label })
    value = shared_attribs.merge(value.is_a?(Hash) ? value : { content: value })

    if bold_label
      label = label.merge({ font_style: :bold })
    end

    [ label, value ]
  end

end
