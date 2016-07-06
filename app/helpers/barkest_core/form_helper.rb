module BarkestCore
  ##
  # This module contains a number of utility functions to make generating forms even easier.
  module FormHelper

    ##
    # Creates a date picker selection field using a bootstrap input group.
    #
    # Valid options:
    # *   +input_group_size+
    #     Valid optional sizes are 'small' or 'large'.
    # *   +readonly+
    #     Set to true to make the input field read only.
    # *   +pre_calendar+
    #     Set to true to put a calendar icon before the input field.
    # *   +post_calendar+
    #     Set to true to put a calendar icon after the input field.  This is the default setting.
    # *   +pre_label+
    #     Set to a text value to put a label before the input field.  Replaces +pre_calendar+ if specified.
    # *   +post_label+
    #     Set to a text value to put a label after the input field.  Replaces +post_calendar+ if specified.
    def date_picker_field(f, method, options = {})
      options = {
          class:            'form-control',
          read_only:        false,
          pre_calendar:     false,
          pre_label:        nil,
          post_calendar:    true,
          post_label:       false,
          attrib_val:       { },
          style:            { },
          input_group_size: ''
      }.merge(options)

      style = ''
      options[:style].each { |k,v| style += "#{k}: #{v};" }

      attrib = options[:attrib_val]
      attrib[:class] = options[:class]
      attrib[:style] = style
      attrib[:readonly] = 'readonly' if options[:read_only]

      if options[:input_group_size] == 'sm' || options[:input_group_size] == 'small' || options[:input_group_size] == 'input-group-sm'
        options[:input_group_size] = 'input-group-sm'
      elsif options[:input_group_size] == 'lg' || options[:input_group_size] == 'large' || options[:input_group_size] == 'input-group-lg'
        options[:input_group_size] = 'input-group-lg'
      else
        options[:input_group_size] = ''
      end


      attrib[:value] = f.object.send(method).to_s(:date4) if f.object.send(method)
      fld = f.text_field(method, attrib)

      # must have at least one attachment, default to post-calendar.
      options[:post_calendar] = true unless options[:pre_calendar] || options[:pre_label] || options[:post_label]

      # labels override calendars.
      options[:pre_calendar] = false if options[:pre_label]
      options[:post_calendar] = false if options[:post_label]

      # construct the prefix
      if options[:pre_calendar]
        pre = '<span class="input-group-addon"><i class="glyphicon glyphicon-calendar"></i></span>'
      elsif options[:pre_label]
        pre = "<span class=\"input-group-addon\">#{h options[:pre_label]}</span>"
      else
        pre = ''
      end

      # construct the postfix
      if options[:post_calendar]
        post = '<span class="input-group-addon"><i class="glyphicon glyphicon-calendar"></i></span>'
      elsif options[:post_label]
        post = "<span class=\"input-group-addon\">#{h options[:post_label]}</span>"
      else
        post = ''
      end

      # and then the return value.
      "<div class=\"input-group date #{options[:input_group_size]}\">#{pre}#{fld}#{post}</div>".html_safe
    end

    ##
    # Creates an input group containing multiple input fields.
    #
    # Valid options:
    # *   +input_group_size+
    #     Valid optional sizes are 'small' or 'large'.
    # *   +readonly+
    #     Set to true to make the input field read only.
    def multi_input_field(f, methods, options = {})
      raise ArgumentError.new('methods must respond to :count') unless methods.respond_to?(:count)

      options = {
          class:            'form-control',
          read_only:        false,
          attrib_val:       { },
          style:            { },
          input_group_size: ''
      }.merge(options)

      style = ''
      options[:style].each do |k,v|
        if k.to_s == 'width'
          options[:input_group_width] = "width: #{v};"
        else
          style += "#{k}: #{v};"
        end
      end

      attrib = options[:attrib_val]
      attrib[:class] = options[:class]
      attrib[:readonly] = 'readonly' if options[:read_only]

      if options[:input_group_size] == 'sm' || options[:input_group_size] == 'small' || options[:input_group_size] == 'input-group-sm'
        options[:input_group_size] = 'input-group-sm'
      elsif options[:input_group_size] == 'lg' || options[:input_group_size] == 'large' || options[:input_group_size] == 'input-group-lg'
        options[:input_group_size] = 'input-group-lg'
      else
        options[:input_group_size] = ''
      end

      fld = []

      remaining_width = 100
      width = (100.0 / methods.count).round(2)

      builder = Proc.new do |method,label|
        width = remaining_width if width > remaining_width
        remaining_width -= width
        attrib[:style] = style + "width: #{width}%;"
        attrib[:value] = f.object.send(method)
        attrib[:placeholder] = label.blank? ? method.to_s.humanize : label
        fld << f.text_field(method, attrib)
      end

      if methods.is_a?(Array)
        methods.each do |method|
          builder.call method, method.to_s.humanize
        end
      elsif methods.is_a?(Hash)
        methods.each do |method,label|
          builder.call method, label.to_s
        end
      else
        raise ArgumentError.new('methods must either be an array or a hash')
      end

      "<div class=\"input-group #{options[:input_group_size]}\" style=\"#{options[:input_group_width]}\">#{fld.join}</div>".html_safe
    end

    ##
    # Creates a currency input field.
    #
    # Specify the +currency_symbol+ if you want it to be something other than '$'.
    # Additional options are passed on to the text field.
    def currency_field(f, method, options = {})
      # get the symbol for the field.
      sym = '$'
      if options[:currency_symbol]
        sym = options[:currency_symbol]
        options.except! :currency_symbol
      end

      # get the value
      if (val = f.object.send(method))
        options[:value] = number_with_precision val, precision: 2, delimiter: ','
      end

      # build the field
      fld = f.text_field(method, options)

      # return the value.
      "<div class=\"input-symbol\"><span>#{h sym}</span>#{fld}</div>".html_safe
    end

    ##
    # Creates a form group including a label and a text field.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def text_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = f.label method, lopt.delete(:text), lopt
      fld = gopt[:wrap].call(f.text_field(method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a text area.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def textarea_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = f.label method, lopt.delete(:text), lopt
      fld = gopt[:wrap].call(f.text_area(method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a currency field.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def currency_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = f.label method, lopt.delete(:text), lopt
      fld = gopt[:wrap].call(currency_field(f, method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a static field.
    # The static field is simple a readonly input field with no name.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def static_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = f.label method, lopt.delete(:text), lopt
      fld = gopt[:wrap].call("<input type=\"text\" class=\"form-control disabled\" readonly=\"readonly\" value=\"#{h(fopt[:value] || f.object.send(method))}\">")
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a date picker field.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def date_picker_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = f.label method, lopt.delete(:text), lopt
      fld = gopt[:wrap].call(date_picker_field(f, method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a multiple input field.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def multi_input_form_group(f, methods, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lopt[:text] ||= gopt[:label]
      if lopt[:text].blank?
        lopt[:text] = methods.map {|k,_| k.to_s.humanize }.join(', ')
      end
      lbl = f.label methods.map{|k,_| k}.first, lopt[:text], lopt
      fld = gopt[:wrap].call(multi_input_field(f, methods, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a form group including a label and a checkbox.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def checkbox_form_group(f, method, options = {})
      gopt, lopt, fopt = split_form_group_options({ class: 'checkbox', field_class: ''}.merge(options))

      if gopt[:h_align]
        gopt[:class] = gopt[:class].blank? ?
            "col-sm-#{12-gopt[:h_align]} col-sm-offset-#{gopt[:h_align]}" :
            "#{gopt[:class]} col-sm-#{12-gopt[:h_align]} col-sm-offset-#{gopt[:h_align]}"
      end

      lbl = f.label method do
        f.check_box(method, fopt) + h(lopt[:text] || method.to_s.humanize)
      end

      "<div class=\"#{gopt[:h_align] ? 'row' : 'form-group'}\"><div class=\"#{gopt[:class]}\">#{lbl}</div></div>".html_safe
    end

    ##
    # Creates a form group including a label and a collection select field.
    #
    # To specify a label, set the +label_text+ option, otherwise the method name will be used.
    # Prefix field options with +field_+ and label options with +label_+.
    # Any additional options are passed to the form group.
    def select_form_group(f, method, collection, value_method = nil, text_method = nil, options = {})
      gopt, lopt, fopt = split_form_group_options({ field_include_blank: true }.merge(options))
      lbl = f.label method, lopt.delete(:text), lopt
      value_method ||= :to_s
      text_method ||= :to_s
      opt = {}
      [:include_blank, :prompt, :include_hidden].each do |attr|
        if fopt[attr] != nil
          opt[attr] = fopt[attr]
          fopt.except! attr
        end
      end
      fld = gopt[:wrap].call(f.collection_select(method, collection, value_method, text_method, opt, fopt))
      form_group lbl, fld, gopt
    end

    private

    def form_group(lbl, fld, opt)
      ret = '<div'
      ret += " class=\"#{h opt[:class]}" unless opt[:class].blank?
      ret += '"'
      ret += " style=\"#{h opt[:style]}\"" unless opt[:style].blank?
      ret += ">#{lbl}#{fld}</div>"
      ret.html_safe
    end

    def split_form_group_options(options)
      options = {class: 'form-group', field_class: 'form-control'}.merge(options || {})
      group = {}
      label = {}
      field = {}

      options.keys.each do |k|
        sk = k.to_s
        if sk.index('label_') == 0
          label[sk[6..-1].to_sym] = options[k]
        elsif sk.index('field_') == 0
          field[sk[6..-1].to_sym] = options[k]
        else
          group[k.to_sym] = options[k]
        end
      end

      group[:wrap] = Proc.new do |fld|
        fld
      end
      if group[:h_align]
        if group[:h_align].is_a?(TrueClass)
          l = 3
        else
          l = group[:h_align].to_i
        end
        l = 1 if l < 1
        l = 6 if l > 6
        f = 12 - l
        group[:h_align] = l
        label[:class] = label[:class].blank? ? "col-sm-#{l} control-label" : "#{label[:class]} col-sm-#{l} control-label"
        group[:wrap] = Proc.new do |fld|
          "<div class=\"col-sm-#{f}\">#{fld}</div>"
        end
      end

      [group, label, field]
    end

  end
end

# :enddoc:

ActionView::Helpers::FormBuilder.class_eval do
  def date_picker_field(method, options = {})
    @template.send(:date_picker_field, self, method, options)
  end

  def multi_input_field(methods, options = {})
    @template.send(:multi_input_field, self, methods, options)
  end

  def currency_field(method, options = {})
    @template.send(:currency_field, self, method, options)
  end

  def text_form_group(method, options = {})
    @template.send(:text_form_group, self, method, options)
  end

  def textarea_form_group(method, options = {})
    @template.send(:textarea_form_group, self, method, options)
  end

  def currency_form_group(method, options = {})
    @template.send(:currency_form_group, self, method, options)
  end

  def static_form_group(method, options = {})
    @template.send(:static_form_group, self, method, options)
  end

  def date_picker_form_group(method, options = {})
    @template.send(:date_picker_form_group, self, method, options)
  end

  def multi_input_form_group(method, options = {})
    @template.send(:multi_input_form_group, self, method, options)
  end

  def select_form_group(method, collection, value_method = nil, text_method = nil, options = {})
    @template.send(:select_form_group, self, method, collection, value_method, text_method, options)
  end
end
