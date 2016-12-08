pdf_doc(
    title: 'Test Report',

    # override the user/timestamp to ensure a consistent result.
    footer_left: 'Testing...',

    # override the report path, keep it consistent with different params.
    footer_center: barkest_core_test_report_path(format: :pdf),

    # override the attributes to ensure a consistent result.
    creation_date: Time.zone.local(2016, 12, 8, 15, 0),
    producer: 'BarkerEST Core Test',
    creator: 'BarkerEST'
) do |pdf|
  pdf.header 4, 'Test Report'

  pdf.table_builder(
         width_ratio: 1.0,
         column_ratios: [ 0.12, 0.22, 0.22, 0.12, 0.12, 0.1, 0.1 ],
         header: true,  # turn the first row into a header that repeats on every page.
  ) do |t|
    t.row do
      t.cells font_style: :bold_italic,
              borders: [ :bottom ],
              border_width: 0.5,
              cell_4_align: :right,
              cell_5_align: :right,
              cell_6_align: :right,
              cell_7_align: :right,
              values: [ 'Code', 'Name', 'Email', 'Birth Date', 'Hire Date', 'Pay Rate', 'Hours' ]
    end
    @data.each do |item|
      t.row do
        t.cells values: [
            item.code,
            item.name,
            item.email,
            fmt_date(item.date_of_birth),
            fmt_date(item.hire_date),
            fixed(item.pay_rate),
            item.hours
        ],
            cell_4_align: :right,
            cell_5_align: :right,
            cell_6_align: :right,
            cell_7_align: :right
      end
    end
  end
end
