Rails.application.routes.draw do

  get 'test_report/csv'

  get 'test_report/xlsx'

  get 'test_report/pdf'

end
