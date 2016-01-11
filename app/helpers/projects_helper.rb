module ProjectsHelper
	def get_stat(issue, integration_end_date = nil, is_qa_tasks = false)
		@stat = [0, 0, 0, 0, 0, 0, "0", "0", "0", "0", "0", "0", "", 0] #total, passed, failed, in-progress
		@test_prep_stat = Array.new(2, 0) #total, ready
		if is_qa_tasks
			issue.subtasks.each do |subtask|
				@qa_tasks.each do |qa_task|
					if subtask['key'] == qa_task.key
						if subtask['fields']['summary'].include? 'Testing'
							check_links(qa_task)
						else
							check_links(qa_task, true)
						end
					end
				end
			end
			if @stat[0] < @test_prep_stat[0]
				@stat[0] = @test_prep_stat[1] if @test_prep_stat[1] > @stat[0]
			end
			@stat[12] = [@test_prep_stat[0], @test_prep_stat[1], @stat[0] ].max.to_s
		else
			check_links(issue)
		end
		@stat[4] = (@stat[0] > 0) ? ((@stat[1] + @stat[2]) * 100.0 / @stat[0]).round : 0
		@stat[5] = (@stat[0] > 0) ? (@stat[1] * 100.0 / @stat[0]).round : 0
		r = LastReport.where("issue = '#{issue.key}'").order('created_at DESC').limit(1).to_a
		if r.empty?
			r = LastReport.new
		else
			r = r[0]
		end
		@stat[6] = set_sign(@stat[0], r.total)
		@stat[7] = set_sign(@stat[1], r.passed)
		@stat[8] = set_sign(@stat[2], r.failed)
		@stat[9] = set_sign(@stat[3], r.inprogress)
		@stat[10] = "" #set_sign(@stat[4], r.p_executed)
		@stat[11] = "" #set_sign(@stat[5], r.p_passed)
		p = TestPreparation.where(issue: issue.key).to_a
		unless p.empty?
			e = p[0]
			if e.tc_plan.to_i <= @stat[0]
				@stat[12] = '<span style="color:green">(100%)</span>' unless (@stat[1] == @stat[0]) && (@stat[1] > 0)
			else
				@stat[12] = "of #{e.tc_plan.to_i}<br />(EDC #{e.tc_date.to_date})"
			end
			unless e.complete_date.nil?
				if e.tc_date.to_date > Time.now.to_date
					z = 0
				elsif (e.complete_date.to_date < Time.now.to_date) || (@stat[0] == @stat[1])
					z = 100
				else
					#d = (e.complete_date.to_date - e.tc_date.to_date).to_i
					d = date_interval(e.tc_date.to_date, e.complete_date.to_date)
					if d > 0
						#z = ((Time.now.to_date - e.tc_date.to_date).to_i * 100.0 / d).round
						z = (date_interval(e.tc_date.to_date, Time.now.to_date).to_i * 100.0 / d).round
					end
				end
				@stat[13] = z
			end
		else
			if !integration_end_date.nil?
				if integration_end_date < Time.now.to_date
					z = 100
				else
					z = ((1-date_interval(Time.now.to_date, integration_end_date).to_i / 30.0) * 100.0).round
					z = 0 if z < 0
				end
				@stat[13] = z
			elsif (@stat[0] == @stat[1]) && (@stat[0] > 0)
				@stat[13] = 100
			end
		end
	end
	
	def date_interval(date1, date2)
		(date1..date2).select {|d| (1..5).include?(d.wday) }.size
	end
	
	def set_sign(x1, x2)
		if x1.to_i > x2.to_i
			"(+#{x1.to_i - x2.to_i})"
		elsif x1.to_i < x2.to_i
			""#"(-#{x2.to_i - x1.to_i})"
		else
			""
		end
	end
	
	def check_links(issue, test_prep = false)
		issue.issuelinks.each do |link|
			if !link['outwardIssue'].nil?
				add_stat(link['outwardIssue'], test_prep)
			elsif !link['inwardIssue'].nil?
				add_stat(link['inwardIssue'], test_prep)
			end
		end
	end
	
	def add_stat(i, test_prep)
		if i['fields']['issuetype']['name'] == 'Test Case'
			if test_prep
				@test_prep_stat[0] += 1
				@test_prep_stat[1] += 1 if i['fields']['status']['name'] == 'Open'
			else
				@stat[0] += 1
				@stat[1] += 1 if (i['fields']['status']['name'][0..5] == 'Passed') || (i['fields']['status']['name'] == 'Cancelled')
				@stat[2] += 1 if (i['fields']['status']['name'] == 'Failed') || (i['fields']['status']['name'] == 'Blocked')
				@stat[3] += 1 if i['fields']['status']['name'] == 'In Progress'
			end
		end
	end
	
	def get_bug_stat(issue)
		@bug_stat = [[0,0,0,0,0,0], [0,0,0,0,0,0], [0,0,0,0,0,0], [0,0,0,0,0,0]] # total, open, closed, on hold //// total, blocker, critical, major, nornal, low
		@issues.each do |bug|
			if bug.parent['key'] == issue.key
				add_bug_stat(0, bug)
				add_bug_stat(1, bug) if bug.fields['status']['name'] == 'Open'
				add_bug_stat(2, bug) if bug.fields['status']['name'] == 'Closed'
				add_bug_stat(3, bug) if bug.fields['status']['name'] == 'On Hold'
			end
		end
	end
	
	def add_bug_stat(i, bug)
		@bug_stat[i][0] += 1
		@bug_stat[i][1] += 1 if bug.fields['priority']['name'] == 'Blocker'
		@bug_stat[i][2] += 1 if bug.fields['priority']['name'] == 'Critical'
		@bug_stat[i][3] += 1 if bug.fields['priority']['name'] == 'Major'
		@bug_stat[i][4] += 1 if bug.fields['priority']['name'] == 'Normal'
		@bug_stat[i][5] += 1 if bug.fields['priority']['name'] == 'Low'
	end
	
	def get_bugzilla_key(name)
		a = name.split(' ')
		k = ''
		if a[0].to_i > 0
			k = a[0]
		else
			a.each_with_index do |aa, i|
				aaa = aa.downcase
				if aaa[0..2] == 'bug'
					if a.size > i+1
						if a[i+1].to_i > 0
							k = a[i+1]
							break
						end
					end
				end
			end
			#a[1].to_i > 0
			#k = a[1]
		end
		k
	end
	
	def find_summary_by_key(key)
		unless @wi_list.nil?
			@wi_list.each do |a|
				if a[1] == key
					return a[0]
				end
			end
		end
		unless @wi.nil?
			@wi.each do |issue|
				if issue.key == key
					return issue.fields['summary']
				end
			end
		end
		key
	end
	
	def get_cr_number_by_key(key)
		@wi.each do |issue|
			if issue.key == key
				return issue.fields['summary']
			end
		end
		key
	end
	
	def get_tms_link(k, s = k)
		link_to "#{s}", "#{@browse_address}#{k}", target: '_blank'
	end
	
	def get_bigzilla_link(summary)
		b_key = get_bugzilla_key(summary)
		link_to "#{b_key}", "#{@bugzilla}#{b_key}", target: '_blank'
	end
	
	def get_list_components(issue)
		a = issue.fields['components']
		return '' if a.nil?
		a.map{ |e| e['name']}.join(', ')
	end
	
	def get_list_blocks(issue, type, type_of_blocks = 'outwardIssue')
		a = issue.fields['issuelinks'].select{ |e| e['type']['name'] == type }
		return '' if a.nil?
		a.map { |e| get_block_fields(e[type_of_blocks]) }.select{ |e| e != '' }.join(', ')
	end
	
	def get_block_fields(subissue)
		return '' if subissue.nil?
		key = subissue['key']
		issue_fields = subissue['fields']
		"#{get_tms_link(key)} #{add_field_images(issue_fields['issuetype'], issue_fields['priority'], issue_fields['status'])}"
	end
	
	def add_field_images(*fields)
		fields.inject('') { |ac, field| [ac, add_field_image(field) ].join(' ') }
	end
	
	def add_field_image(field)
		"<img alt=\"#{field['name']}\" src=\"#{field['iconUrl']}\" title=\"#{field['name']}\" />"
	end
	
	def get_count_blocks(issue, type, type_of_blocks, issue_types)
		a = issue.fields['issuelinks'].select{ |e| e['type']['name'] == type }
		#a = type.kind_of?(Array) ? a.select{ |e| type.include?(e['type']['name']) } : a.select{ |e| e['type']['name'] == type }
		return '' if a.nil?
		c = a.inject(0) { |sum, e| sum + count_blocks_issues(e[type_of_blocks], issue_types) }
		(c == 0) ? '' : c
	end
	
	def sum_blocks(*ar)
		c = ar.inject(0) { |ac, e| ac + get_count_blocks(e[0], e[1], e[2], e[3]).to_i }
		(c == 0) ? '' : c
	end
	
	def count_blocks_issues(subissue, subissue_type)
		return 0 if subissue.nil?
		issue_type = subissue['fields']['issuetype']['name']
		#Rails.logger.info("type: #{subissue_type.inspect}")
		return 0  unless subissue_type.include?(issue_type)
		status = subissue['fields']['status']['name']
		return 0 if ['Closed', 'Cancelled', 'Ready for Testing', 'Passed', 'Passed With Minor Defects'].include?(status)
		return 1
	end
	
	def get_last_reopened(issue)
		key = issue.key
		a = @changelog_updates.find{ |e| e['key'] == key }
		return '' if a.nil?
		a['status'].select{ |e| e[0] == 'Reopened'}.sort_by{ |e| e[1] }.last.to_a[1]
	end
	
	def last_status_change_date(issue_key, ret_default = '', is_last = true)
		@changelog_updates.each do |upd|
			if upd['key'] == issue_key && !upd['status'].nil? && upd['status'].size > 0
				return is_last ? upd['status'][-1][1] : upd['status']
				#upd['status'].each do |st|
				#	return st[1] if st[0] == 'Closed'
				#end
			end
		end
		ret_default
	end
	
	def label_added(issue_key, labels, issue_labels, issue_created)
		@changelog_updates.each do |upd|
			if upd['key'] == issue_key
				upd['labels'].each do |st|
					labels.each do |label|
						return st if st[0].include? label
					end
				end
			end
		end
		issue_labels.each do |i_label|
			labels.each do |label|
				return [i_label, issue_created] if i_label.include? label
			end
		end
		''
	end
	
	def is_opened?(issue, date1, date2)
		get_open_intervals(issue.key).each do |i|
			return true if i[0].to_date >= date1 && i[0].to_date <= date2
		end
		false
	end
	
	def is_opened_on_date?(issue, date1)
		get_open_intervals(issue.key).each do |i|
			return true if i[1].to_date >= date1 && i[0].to_date <= date1
		end
		false
	end
	
	def is_issue_exists?(issue, date1)
		return true if issue.fields['created'].to_date <= date1
		false
	end
	
	def opened_issues_on_date(issues_list, date1)
		n = 0
		issues_list.each do |i|
			n += 1 if is_opened_on_date?(i, date1)
		end
		n
	end
	
	def existed_issues_on_date(issues_list, date1)
		n = 0
		issues_list.each do |i|
			n += 1 if is_issue_exists?(i, date1)
		end
		n
	end
	
	def changed_status_from_to_during_week(from_status, to_status, y_week_n)
		n = 0
		@changelog_updates.each do |upd|
			if !upd['status'].nil? && upd['status'].size > 0
				prev_st = nil
				upd['status'].each do |st|
					if st[0] == to_status && year_plus_week(st[1]) == y_week_n
						n += 1 if !prev_st.nil? && prev_st[0] == from_status || from_status == 'ANY'
					end
					prev_st = st
				end
			end
		end
		n
	end
	
	def have_status_at_start_week(s_status, y_w)
		n = 0
		d1 = Date.commercial(y_w.to_s[0..3].to_i, y_w.to_s[4..5].to_i, 1) - 1.day
		@changelog_updates.each do |upd|
			if !upd['status'].nil? && upd['status'].size > 0
				prev_st = nil
				upd['status'].each do |st|
					if !prev_st.nil?
						n += 1 if prev_st[0] == s_status && prev_st[1].to_date <= d1 && st[1].to_date > d1
					end
					prev_st = st
				end
			end
		end
		n
	end
	
	def have_status_this_week(s_status, y_w)
		have_status_at_start_week(s_status, y_w) + changed_status_from_to_during_week('ANY', s_status, y_w)
	end
	
	def year_plus_week(i_date)
		(i_date.to_date.strftime('%Y') + "#{i_date.to_date.cweek}".rjust(2,'0')).to_i
	end
	
	def show_week_days(y_w)
		y = y_w.to_s[0..3].to_i
		w = y_w.to_s[4..5].to_i
		d1 = Date.commercial(y, w, 1).strftime("%Y-%m-%d")
		d2 = Date.commercial(y, w, 7).strftime("%Y-%m-%d")
		"#{w}/#{y}: #{d1}-#{d2}"
	end
	
	def get_open_intervals(issue_key)
		lst = last_status_change_date(issue_key, '', false)
		opened = []
		d1 = lst[0][1]
		op_st = true
		lst.each do |st|
			if op_st && st[0] == 'Closed'
				opened << [ d1, st[1] ]
				op_st = false
			elsif !op_st && st[0] == 'Reopened'
				d1 = st[1]
				op_st = true
			end
		end
		opened << [ d1, (Time.now + 7.day).strftime("%Y-%m-%d") ] if op_st
		opened
	end
	
	def color_bool(t1,stat1,prior1)
		if stat1 == 'On Hold' || stat1 == 'Closed'
			false
		elsif prior1 == 'Blocker' && t1 > 1
			true
		elsif prior1 == 'Critical' && t1 > 2
			true
		elsif prior1 == 'High' && t1 > 4
			true
		elsif prior1 == 'Medium' && t1 > 7
			true
		elsif t1 > 14
			true
		else
			false
		end
	end 	
	
end
