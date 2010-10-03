class TimeShiftsController < ApplicationController
  before_filter :find_time_shift, :only =>[:show, :destroy]

  def index
    @data = mechanized_session.get_index
    @hours = @data[:time_shifts].reverse
    @missing = @data[:missing]
    hours_today = @hours.select{|ts| ts.date == Date.today}.sum(&:hours_worked)
    @missing << Date.today.strftime("%m/%d") if (1..5).include?(Date.today.wday) && hours_today < 8.0
    respond_to do |format|
      format.html {}
      format.xml { render :xml => @hours.collect(&:to_hash).to_xml(:root => "hours") }
    end
  end

  def show
  end

  def new
    @data = mechanized_session.get_index
    @project_names = @data[:projects]
    @dates = params[:all] ? TimeShift.all_dates : TimeShift.possible_dates
    @hours = @data[:time_shifts].reverse
    @time_shift = TimeShift.new(params[:time_shift])
    if @data[:time_shifts].last
      prev_project_name = @data[:time_shifts].last.project_name
      @time_shift.project_id ||= @data[:projects].detect{|name, id| name == prev_project_name}
    end
    @time_shift.hours_worked ||= 8
  end

  def create
    hour = TimeShift.new(params["time_shift"])
    mechanized_session.create_entry(hour)
    redirect_to root_path
  end

  def destroy
    mechanized_session.delete_entry(@hour)
    redirect_to root_path
  end

  private

  def find_time_shift
    @data = mechanized_session.get_index
    @hour = @data[:time_shifts].detect{|ts| ts.id == params[:id].to_i }
  end
end