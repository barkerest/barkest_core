class TestReportController < ApplicationController

  class SampleObject
    include ActiveModel::Model

    attr_accessor :code, :name, :email, :date_of_birth, :hire_date, :pay_rate, :hours
  end

  private_constant :SampleObject

  before_action :require_admin
  before_action :load_sample_data

  def csv
  end

  def xlsx
  end

  def pdf
  end

  private

  def require_admin
    authorize! true
  end

  def load_sample_data
    @data = {}
    if Rails.env.development?
      100.times do

      end
    else
      @data << SampleObject.new(
          code: 'SMIJOH',
          name: 'John Smith',
          email: 'j.smith@example.com',
          date_of_birth: Time.new(1980, 1, 1).utc,

      )
    end

  end

end
