class TrackerSession < MechanizedSession
  BASE_URL = "https://www.pivotaltracker.com"
  action :login do |session, options|
    success = false
    session.get("#{BASE_URL}/") do |page|
      post_login_page = page.form_with(:action =>"#{BASE_URL}/signin") do |form|
        form["credentials[username]"] = options[:username]
        form["credentials[password]"] = options[:password]
        form.checkbox_with(:name => /remember/).check
        session.logger.debug "Submitting /signin form"
      end.click_button
      session.logger.debug "Ended up on page #{post_login_page.uri}"
      success = post_login_page.uri != page.uri
    end
    success
  end

  action :get_index do |session, options|
    missing = session.post_login_page.parser.css('#delinquency_alert_detail').inner_text.gsub('Enter hours now >', '').strip
    missing = missing.gsub!("missing", "").gsub!(/[^0-9\/,]/, "").split(",") if missing.present?
    session.logger.debug "Found missing text: #{missing.inspect}"
    hours = []
    projects = []
    session.get("#{BASE_URL}/time_shifts?date_period[start]=#{TimeShift.last_pay_period.last}&date_period[finish]=#{TimeShift.this_pay_period.first}") do |page|
      session.check_for_signed_out!(page)
      rows = page.parser.css('table#shift_table tr.light, table#shift_table tr.dark')
      rows.each do |row|
        date = row.css("td:first-child").inner_text.strip
        project_name = row.css("td.project").inner_text.strip
        hours_worked = row.css("td.hours").inner_text.strip.to_f
        description = row.css("td.hours + td").inner_text.strip
        id = row.css("td.action + td.action a").first.attribute('href').value.match(/\d+$/)[0].to_i
        hours << TimeShift.new(:date => date, :project_name => project_name, :hours_worked => hours_worked, :description => description, :id => id)
      end
      projects = page.forms[0].fields[0].options[1..-1].collect { |o| [o.text, o.value] }
    end
    {:time_shifts => hours.sort_by(&:date), :missing => missing, :projects => projects}
  end

  action :delete_entry do |session, hour|
    post_delete_page = session.delete("#{BASE_URL}/time_shifts/#{hour.id}")
    session.check_for_signed_out!(post_delete_page)
  end

  action :create_entry do |session, hour|
    session.get("#{BASE_URL}/time_shifts/new") do |page|
      session.check_for_signed_out!(page)
      post_create_page = page.form_with(:action => '/time_shifts') do |f|
        f['shift[project_id]'] = hour.project_id
        f['shift[date]'] = hour.date
        f['shift[hours]'] = hour.hours_worked
        f['shift[description]'] = hour.description
      end.click_button
      session.check_for_signed_out!(post_create_page)
    end
  end

  def signed_out?(page)
    page.parser.inner_text.include?('Email or Username')
  end

  def post_login_page
    @post_login_page ||= self.get("#{BASE_URL}/")
  end
end