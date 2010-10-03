class TimeShift
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :hours_worked
  attr_accessor :date
  attr_accessor :project_name
  attr_accessor :project_id
  attr_accessor :description
  attr_accessor :id

  def initialize(params = nil)
    (params || {}).each do |k,v|
      self.send("#{k}=", v)
    end
  end

  def persisted?
    false
  end

  def to_hash
    {:hours_worked => hours_worked, :date =>date, :project_name => project_name, :description =>description}
  end

  def days_ago
    Date.today - self.date
  end

  def date=(date_str)
    @date = Date.parse(date_str)
  end

  def self.possible_dates
    ranges = []
    ranges << ["This Pay Period", this_pay_period.reject{|d| d.wday == 0 || d.wday == 6}]
    ranges << ["Last Pay Period", last_pay_period.reject{|d| d.wday == 0 || d.wday == 6}]
    ranges
  end

  def self.all_dates
    ranges = []
    ranges << ["This Pay Period", this_pay_period]
    ranges << ["Last Pay Period", last_pay_period]
    ranges
  end

  def self.this_pay_period
    if Date.today.day <= 15
      ((Date.today.beginning_of_month)..Date.today).to_a.reverse
    else
      ((Date.today.beginning_of_month + 15.days)..Date.today).to_a.reverse
    end
  end

  def self.last_pay_period
    if Date.today.day <= 15
      ((Date.today.beginning_of_month - 1.month + 15.days)...(Date.today.beginning_of_month)).to_a.reverse
    else
      ((Date.today.beginning_of_month)...(Date.today.beginning_of_month + 15.days)).to_a.reverse
    end
  end

  def to_param
    id.to_s
  end
end