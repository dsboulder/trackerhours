class TrackerSession
  class SignoutError < StandardError; end

  attr_reader :token

  def initialize(username_or_token, password = nil)
    if password
      @username = username_or_token
      @password = password
    else
      @token = username_or_token
    end
  end

  def get_index
    a = agent
    missing = post_login_page.parser.css('#delinquency_alert_detail').inner_text.gsub('Enter hours now >', '').strip
    missing = missing.gsub!("missing", "").gsub!(/[^0-9\/,]/, "").split(",") if missing.present?
    hours = []
    projects = []
    a.get("/time_shifts?date_period[start]=#{TimeShift.last_pay_period.last}&date_period[finish]=#{TimeShift.this_pay_period.first}") do |page|
      check_for_signout!(page)
      rows = page.parser.css('table#shift_table tr.light, table#shift_table tr.dark')
      rows.each do |row|
        date = row.css("td:first-child").inner_text.strip
        project_name = row.css("td.project").inner_text.strip
        hours_worked = row.css("td.hours").inner_text.strip.to_f
        description = row.css("td.hours + td").inner_text.strip
        id = row.css("td.action + td.action a").first.attribute('href').value.match(/\d+$/)[0].to_i
        hours << TimeShift.new(:date => date, :project_name => project_name, :hours_worked => hours_worked, :description => description, :id => id)
      end
      projects = page.forms[0].fields[0].options[1..-1].collect{|o| [o.text, o.value]}
    end
    {:time_shifts => hours.sort_by(&:date), :missing => missing, :projects => projects}
  end

  def delete_entry(hour)
    a = agent
    a.delete("https://www.pivotaltracker.com/time_shifts/#{hour.id}")
    true
  end

  def create_entry (hour)
    a = agent
    a.get('https://www.pivotaltracker.com/time_shifts/new') do |page|
      post_create_page = page.form_with(:action => '/time_shifts') do |f|
        f['shift[project_id]'] = hour.project_id
        f['shift[date]'] = hour.date
        f['shift[hours]'] = hour.hours_worked
        f['shift[description]'] = hour.description
      end.click_button
      return true
    end
  end

  def agent
    return @agent if @agent
    a = WWW::Mechanize.new
    cookie = get_cookie_from_token
    uri = URI.parse("https://www.pivotaltracker.com/")
    if cookie
      a.cookie_jar.add(uri, cookie)
    else
      a.get('http://www.pivotaltracker.com/') do |page|
        page.encoding = 'utf-8'
        ActiveRecord::Base.logger.debug page.parser.inner_text        
        @post_login_page = page.form_with(:action => 'https://www.pivotaltracker.com/signin') do |f|
          f['credentials[username]'] = @username
          f['credentials[password]'] = @password
        end.click_button
        ActiveRecord::Base.logger.debug page.parser.inner_text
        check_for_signout!(@post_login_page)
      end
      cookies = a.cookie_jar.cookies(uri)
      ActiveRecord::Base.logger.debug cookies.inspect
      @token = cookies.detect{|c| c.name == "pivotal_t2_session_id"}.value
    end
    @agent = a
  end


  private

  def check_for_signout! (page)
    if page.parser.inner_text.include?('Email or Username')
      ActiveRecord::Base.logger.warn "Signout detected!"
      raise SignoutError
      end
  end

  def get_cookie_from_token
    return nil unless @token
    yaml = <<-YAML
--- !ruby/object:WWW::Mechanize::Cookie
  comment:
  comment_url:
  discard:
  domain: www.pivotaltracker.com
  expires:
  max_age:
  name: pivotal_t2_session_id
  path: /
  port:
  secure: false
  value: #{@token}
  version: 0
    YAML
    YAML.load(yaml)
  end

  def post_login_page
    @post_login_page ||= @agent.get("https://www.pivotaltracker.com/")
  end
end