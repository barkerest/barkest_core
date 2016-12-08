require 'prawn'
require 'prawn/table'
require 'prawn-rails'

##
# Additions and improvements made to the Prawn::Document class.
class Prawn::Document
  ##
  # An object linked to the PDF document.
  #
  attr_accessor :object

  ##
  # Grabs a value from the object, similar to how form helpers do.
  #
  def object_field_value(method)
    meth = "#{method}_before_type_cast"
    if object && object.respond_to?(meth)
      object.send(meth)
    elsif object && object.respond_to?(method)
      object.send(method)
    else
      method.to_s.humanize
    end
  end

  ##
  # Gets the footer values for the current page.
  #
  # Returns an array.
  #
  def footer_values
    @footer_values ||= []
    @footer_values[@page_number] ||= []
  end

  ##
  # Sets the footer values for the current page.
  #
  # The +values+ should be provided as an array with up to three values.
  # The first value is the left text, the second is the center text, and the third is the right text.
  #
  #   [ 'Left', 'Center', 'Right' ]
  #
  # Any value that is nil will get replaced with the default value for the position based on how the PDF
  # document was configured.  This is of course, only true if you are using the PdfHelper::pdf_doc helper function.
  # If you are working with the document yourself, this is a place to cache the footer values for later usage.
  #
  def footer_values=(values)
    @footer_values ||= []
    values = [values] * 3 unless values.is_a?(Array)
    @footer_values[@page_number] = values
  end

  ##
  # Uses the grid system to create a bounding box and then executes the provided code block.
  #
  # The bounding box can be defined in percentage as opposed to absolutes.
  #
  # Valid options:
  #
  # rectangle::
  #   Allows you to specify the dimensions of the box with a single value.  You can provide an array or a hash
  #   to this option.
  #       [ column, row, width, height ]
  #       { :column => ?, :row => ?, :width => ?, :height => ? }
  #       { :left => ?, :top => ?, :width => ?, :height => ? }
  #
  # column::
  #   Sets the starting column for the bounding box.
  #   This will be overridden if +rectangle+ is also set.
  #   This can be either an absolute grid location (5) or a percentage (5%).
  #
  # row::
  #   Sets the starting row for the bounding box.
  #   This will be overridden if +rectangle+ is also set.
  #   This can be either an absolute grid location (5) or a percentage (5%).
  #
  # width::
  #   Sets the width for the bounding box.
  #   This will be overridden if +rectangle+ is also set.
  #   This can be either an absolute grid location (5) or a percentage (5%).
  #
  # height::
  #   Sets the height for the bounding box.
  #   This will be overridden if +rectangle+ is also set.
  #   This can be either an absolute grid location (5) or a percentage (5%).
  #
  # fill_width::
  #   If set, the width will spring out to fill the grid from the starting column.
  #   This overrides both +rectangle+ and +width+.
  #
  # fill_height::
  #   If set, the height will spring out to fill the grid from the starting row.
  #   This overrides both +rectangle+ and +height+.
  #
  def layout(options = {}, &block)
    options ||= {}

    col_max = grid.columns
    row_max = grid.rows

    if options[:rectangle]
      r = options[:rectangle]
      if r.is_a?(Array)
        options[:column] ||= r[0]
        options[:row] ||= r[1]
        options[:width] ||= r[2]
        options[:height] ||= r[3]
      elsif r.is_a?(Hash)
        options[:column] ||= r[:column] || r[:left]
        options[:row] ||= r[:row] || r[:top]
        options[:width] ||= r[:width]
        options[:height] ||= r[:height]
      end
    end

    col = options[:column] || 1
    row = options[:row] || 1
    width = options[:width] || 1
    height = options[:height] || 1

    ptov = Proc.new do |pval,max,plus|
      if pval.is_a?(String)
        if pval[-1] == '%'
          pval = (pval.to_f * 0.01 * max).to_i + plus
          pval = max if pval > max
          pval = 1 if pval < 1
        else
          pval = pval.to_i
        end
      end
      pval
    end

    col = ptov.call(col, col_max, 1)
    width = ptov.call(width, col_max, 0)
    row = ptov.call(row, row_max, 1)
    height = ptov.call(height, row_max, 0)

    width = col_max - col + 1 if options[:fill_width]
    height = row_max - row + 1 if options[:fill_height]

    raise StandardError.new("column must be between 1 and #{col_max}") unless col >= 1 && col <= col_max
    raise StandardError.new("row must be between 1 and #{row_max}") unless row >= 1 && row <= row_max
    raise StandardError.new('width is invalid') unless width >= 1 && col + width - 1 <= col_max
    raise StandardError.new('height is invalid') unless height >= 1 && row + height - 1 <= row_max

    col -= 1
    row -= 1

    grid([row, col], [row + height - 1, col + width - 1]).bounding_box(&block)
  end

  ##
  # Creates a header row for a page.
  #
  # The text is 20pt and bold.
  # The +height+ would be the height you want your header row to be in percent.  4 is a good starting point for portrait.
  #
  #
  def header(height, *columns)
    columns = columns.to_a.map{ |v| preprocess_table_data(v) }
    layout column: 1, row: 1, fill_width: true, height: height do
      table [
                # row 1
                columns
            ],
            width_ratio: 1.0,
            cell_style: {
                borders: [ :bottom ],
                border_width: 1.5,
                padding: [ 0, 0, 0, 0 ],
                font_style: :bold,
                size: 20
            }
    end
  end

  ##
  # Creates a bounded box inside of the current bounds with side and top padding, then it executes the provided
  # code block.
  #
  # This can be useful to provide padding to the left and above text inside of a layout box.
  #
  def padded(padding = 2, &block)
    r = bounds
    padding ||= 2
    bounding_box([padding, r.top - padding], width: r.width - (2 * padding), &block)
  end

  ##
  # Creates a small box that can be used as a checkbox.
  #
  # The +x+ and +y+ parameters are absolute positions for the checkbox.
  #
  # Valid options:
  #
  # checked::
  #   If set, the box will be marked with an X.
  #
  # stroke_width::
  #   The line width to draw the checkbox with.  Defaults to 0.5.
  #
  # size::
  #   The size of the checkbox.  Defaults to 8.0.
  #
  # rounded::
  #   Set to true to have rounded corners.  Defaults to false.
  #
  # color::
  #   The color to draw the checkbox in.  Defaults to '000000' (black).
  #
  # label::
  #   An optional label to follow the checkbox.
  #
  def checkbox(x, y, options = { })
    options = { stroke_width: 0.5, size: 8, rounded: false, color: '000000' }.merge(options || {})
    stored_line_width = line_width
    stored_color = stroke_color
    self.line_width = options[:stroke_width]
    self.stroke_color = options[:color]
    if options[:rounded]
      stroke_rounded_rectangle [x, y], options[:size], options[:size], options[:size] * 0.2
    else
      stroke_rectangle [x, y], options[:size], options[:size]
    end
    if options[:checked]
      self.stroke_color = '000000'
      self.line_width = options[:size] * 0.125
      offset = options[:size] * 0.1
      stroke_line [x + offset, y - offset], [x + options[:size] - offset, y - options[:size] + offset]
      stroke_line [x + offset, y - options[:size] + offset], [x + options[:size] - offset, y - offset]
    end
    self.line_width = stored_line_width
    self.stroke_color = stored_color
    unless options[:label].blank?
      text_box options[:label], at: [x + options[:size] + 2.pt, y]
    end
  end

  ##
  # Strokes the bottom of the current bounds.
  #
  # The +stroke_width+ is the thickness of the line to draw.
  #
  def stroke_bottom(stroke_width = 0.5)
    stored_line_width = line_width
    self.line_width = stroke_width
    horizontal_line 0, bounds.width, at: 0
    self.line_width = stored_line_width
  end

  ##
  # Gets a filesystem path to a font file.
  #
  def asset_font_path(font_name)
    File.expand_path("../../assets/fonts/#{font_name}", __FILE__)
  end

  ##
  # Gets a filesystem path to an image file.
  #
  def asset_image_path(image_name)
    File.expand_path("../../assets/images/#{image_name}", __FILE__)
  end

  ##
  # Draws text with a line under it.
  #
  # Valid options:
  #
  # at::
  #   The position to draw the text.  Defaults to [0, 0].
  #
  # width::
  #   The width of the text to draw.  Defaults to the actual width of the text.
  #   You can set this to either limit the width of the underline field, or
  #   ensure that the underline field is large enough to fill a void (ie - on a form).
  #
  # height::
  #   The height of the text to draw.  Defaults to the actual height of the text within the width specified.
  #   This can be set to prevent line wrapping if you also specified a width.
  #
  def underline(text, options = {})
    options = { at: [0, 0] }.merge(options || {})
    text ||= ''
    text = Prawn::Text::NBSP if text.empty?
    text_width = options[:width] || width_of(text)
    text_height = options[:height] || height_of(text, width: text_width)
    text_box text, at: options[:at], width: text_width, height: text_height
    stored_line_width = line_width
    stored_stroke_color = stroke_color
    self.line_width = 0.5
    self.stroke_color = '000000'
    y = options[:at][1] - text_height + 2.pt
    x = options[:at][0]
    stroke_line [x, y], [ x + text_width, y ]
    self.line_width = stored_line_width
    self.stroke_color = stored_stroke_color
  end

  ##
  # Generates a text field for a form.
  #
  #   Your Name:______________
  #
  # The label is required, but the value is optional.
  #
  # Valid options:
  #
  # at::
  #   The position to draw the field.  Defaults to [0,0].
  #
  # width::
  #   The width of the field.  Defaults to 2 in.  This is the total width
  #   including both the label and the value.
  #
  def text_field(label, value = nil, options = {})
    options = { at: [0, 0], width: 2.0.in }.merge(options || {})

    value ||= ''
    label_height = height_of(label)
    label_width = width_of(label) + 2.pt
    value_width = options[:width] - label_width
    actual_value_width = width_of(value) + 2.pt
    if value_width < actual_value_width * 0.5
      raise StandardError.new('The width of the text field is not large enough to accomodate the label.')
    end
    y = options[:at][1]
    x = options[:at][0] + label_width

    text_box label, at: options[:at], height: label_height, width: label_width
    text_box value, at: [ x + 2.pt, y ], height: label_height, width: value_width - 4.pt, overflow: :shrink_to_fit
    stored_line_width = line_width
    stored_line_color = stroke_color
    self.line_width = 0.5
    self.stroke_color = '000000'
    stroke_line [x, y - label_height], [x + value_width, y - label_height]
    self.line_width = stored_line_width
    self.stroke_color = stored_line_color
  end

  ##
  # Reverses a y coordinate to be from the top of the bounding box instead of from the bottom.
  #
  def from_top(y)
    bounds.top - bounds.bottom - y
  end

  ##
  # Changes to the specified font style.
  #
  # If a block is provided, the block is executed and then the font style is reverted.
  #
  def font_style(style)
    f = font
    if block_given?
      font(f.name, size: font_size, style: style) do
        yield
      end
    else
      font(f.name, size: font_size, style: style)
    end
  end

end