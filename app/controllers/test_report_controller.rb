class TestReportController < ApplicationController

  class SampleObject
    include ActiveModel::Model

    attr_accessor :code, :name, :email, :date_of_birth, :hire_date, :pay_rate, :hours
  end

  private_constant :SampleObject

  before_action :require_admin
  before_action :load_sample_data

  def index

  end

  # Test result: "Code,Name,Email,Date of Birth,Hire Date,Pay Rate,Hours\nSMIJOH,John Smith,j.smith@example.com,1980-01-01 00:00:00 UTC,2010-05-01 00:00:00 UTC,15.5,2260\n"
  def csv
    render formats: [ :csv ]
  end

  def xlsx
    render formats: [ :xlsx ]
  end

  def pdf
    render formats: [ :pdf ]
  end

  private

  def require_admin
    authorize! true
  end

  def load_sample_data
    @data = []

    if Rails.env.development? && params[:one].blank?
      while @data.length < 100
        fn = Faker::Name.first_name
        ln = Faker::Name.last_name
        code = ln[0...3] + fn[0...3]
        bd = Faker::Date.between(65.years.ago, 19.years.ago).to_time
        hd = Faker::Date.between(bd + 18.years, 6.months.ago).to_time
        pr = (Random.rand(5600) + 900).to_f / 100
        hr = (Random.rand(2000) + 1000)

        @data << SampleObject.new(
            code: code.upcase,
            name: "#{fn} #{ln}",
            email: "#{code.downcase}@example.com",
            date_of_birth: bd,
            hire_date: hd,
            pay_rate: pr,
            hours: hr
        )
      end
    else
      @data << SampleObject.new(
          code: 'SMIJOH',
          name: 'John Smith',
          email: 'j.smith@example.com',
          date_of_birth: Time.zone.local(1980, 1, 1),
          hire_date: Time.zone.local(2010, 5, 1),
          pay_rate: 15.50,
          hours: 2260
      )
    end

    @data.sort!{|a,b| a.code <=> b.code}
  end

end
