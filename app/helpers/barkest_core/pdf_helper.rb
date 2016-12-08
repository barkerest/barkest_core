require 'prawn-rails/document'
require 'prawn/measurement_extensions'
require 'prawn/font'

module BarkestCore
  ##
  # This module defines the method that makes PDF generation just a bit easier.
  #
  module PdfHelper

    ##
    # Creates a PDF document with the specified options.
    #
    # The document will be setup with configured margins, a 100x100 grid, and one embedded font (ArhivoNarrow).
    # Once the document is configured, the +pdf+ will be yielded to the block provided to generate the content.
    #
    # Accepted options:
    #
    # page_layout::
    #     Specify the page layout. This can be either :portrait or :landscape.  Defaults to :portrait.
    #
    # page_size::
    #     Specify the page size.  This defaults to 'LETTER'. See {Prawn PDF Manual}[http://prawnpdf.org/manual.pdf#page=91] for more information.
    #
    # margin::
    #     Specify the margin size.  This can be either a single value or an array of values.  Internally it always
    #     gets converted to an array of values.  If you only specify a single value, it will be filled out as the
    #     margin for all four edges.  Alternatively, you can set :top_margin, :right_margin, :left_margin, and
    #     :bottom_margin individually.
    #
    # top_margin::
    #     Specify the top margin size.  Defaults to 0.5 in.
    #
    # right_margin::
    #     Specify the right margin size.  Defaults to 0.5 in.
    #
    # left_margin::
    #     Specify the left margin size.  Defaults to 0.5 in.
    #
    # bottom_margin::
    #     Specify the bottom margin size.  Defaults to 0.5 in.
    #
    # print_scaling::
    #     Allows you to specify the default print scaling in the print dialog.  Defaults to :none.
    #     See the {Prawn PDF Manual}[http://prawnpdf.org/manual.pdf#page=95] for more information.
    #
    # font_name::
    #     Specify the default font for the document.  Can be one of 'Helvetica', 'Times-Roman', 'Courier', or
    #     'ArchivoNarrow'.  Defaults to 'Helvetica'.
    #
    # font_size::
    #     Specify the default font size for the document.  Defaults to 10 pt.
    #
    # skip_footer::
    #     Set to true to skip footer generation.  Otherwise, once you finish generating content, a footer will
    #     be attached to every page automatically.
    #
    # footer_left::
    #     Set the left footer text.  Defaults to the current user name and time.
    #
    # footer_center::
    #     Set the center footer text.  Defaults to the request path.
    #
    # footer_right::
    #     Set the right footer text.  Defaults to "Page # of #".
    #
    # footer_hr::
    #     Set to true to draw a horizontal rule above the footer, or false to omit the horizontal rule.
    #     Defaults to true.
    #
    # footer_color::
    #     Set the color of the footer text.  Defaults to '000000' (black).
    #
    def pdf_doc(options = {})

      # our default values merged with the configured values and then the options provided.
      options = {
          page_layout: :portrait,
          page_size: 'LETTER',
          margin: [ 0.5.in, 0.5.in, 0.55.in, 0.5.in ],
          print_scaling: :none,
          font_name: 'Helvetica',
          font_size: 10.0
      }.merge(PrawnRails.config.to_h).merge(options || {})

      # build the info
      options[:info] ||= {}
      options[:info].merge!({
                                Title: options.delete(:title) ||  "#{controller_name}##{action_name}",
                                Creator: options.delete(:creator) || Rails.application.app_company,
                                Producer: options.delete(:producer) || Rails.application.app_info,
                                CreationDate: options.delete(:creation_date) || Time.now
                            })

      # build the margin array
      options[:margin] ||= []
      options[:margin] = [ options[:margin] ] * 4 unless options[:margin].is_a?(Array)

      # top margin defaults to 0.5".
      options[:margin][0] = options[:top_margin] if options[:top_margin]
      options[:margin][0] = 0.5.in unless options[:margin][0]

      # right margin defaults to top margin.
      options[:margin][1] = options[:right_margin] if options[:right_margin]
      options[:margin][1] = options[:margin][0] unless options[:margin][1]

      # bottom margin defaults to top margin.
      options[:margin][2] = options[:bottom_margin] if options[:bottom_margin]
      options[:margin][2] = options[:margin][0] unless options[:margin][2]

      # left margin defaults to right margin.
      options[:margin][3] = options[:left_margin] if options[:left_margin]
      options[:margin][3] = options[:margin][1] unless options[:margin][3]

      font_name = options[:font_name] || 'Helvetica'
      font_size = options[:font_size] || 10.0

      skip_footer = options[:skip_footer].nil? ? false : options[:skip_footer]

      footer_left = options[:footer_left].nil? ? "#{current_user.name} - #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}" : options[:footer_left].to_s
      footer_center = options[:footer_center].nil? ? request.fullpath : options[:footer_center].to_s
      footer_right = options[:footer_right].nil? ? nil : options[:footer_right].to_s
      footer_hr = options[:footer_hr].nil? ? true : options[:footer_hr]
      footer_color = options[:footer_color].nil? ? '000000' : options[:footer_color].to_s

      # remove some options that are custom.
      options.except!(
          :title, :creator, :producer, :creation_date,
          :top_margin, :bottom_margin, :left_margin, :right_margin,
          :font_name, :font_size,
          :skip_footer
      )

      left_edge = options[:margin][3]
      right_edge = options[:margin][1]
      bottom_edge = options[:margin][2]

      pdf = PrawnRails::Document.new(options)

      # ArchivoNarrow gives us another sans font that has tighter letter spacing, and it is also a freely available font requiring no licensing.
      pdf.font_families['ArchivoNarrow'] = {
          bold:         { file: pdf.asset_font_path('barkest_core/ArchivoNarrow-Bold.ttf') },
          italic:       { file: pdf.asset_font_path('barkest_core/ArchivoNarrow-Italic.ttf') },
          bold_italic:  { file: pdf.asset_font_path('barkest_core/ArchivoNarrow-BoldItalic.ttf') },
          normal:       { file: pdf.asset_font_path('barkest_core/ArchivoNarrow-Regular.ttf') },
      }

      # set the default font and size
      pdf.font font_name, size: font_size

      # nice fine grid layout.
      pdf.define_grid columns: 100, rows: 100, gutter: 2.5

      yield pdf if block_given?

      unless skip_footer
        pdf.font font_name, size: 8.0 do
          (1..pdf.page_count).each do |pg|
            pdf.go_to_page pg
            pdf.canvas do
              width = pdf.bounds.right - right_edge - left_edge
              if footer_hr
                pdf.stroke_color '000000'
                pdf.stroke { pdf.horizontal_line left_edge, pdf.bounds.right - right_edge, at: bottom_edge }
              end
              pos = [ left_edge, bottom_edge - 3 ]
              pdf.bounding_box(pos, width: width, height: 12) { pdf.text pdf.footer_values[0] || footer_left, align: :left, color: footer_color }
              pdf.bounding_box(pos, width: width, height: 12) { pdf.text pdf.footer_values[1] || footer_center, align: :center, color: footer_color }
              pdf.bounding_box(pos, width: width, height: 12) { pdf.text pdf.footer_values[2] || (footer_right || "Page #{pg} of #{pdf.page_count}"), align: :right, color: footer_color }
            end
          end
        end
      end

      pdf.render

    end
  end

end
