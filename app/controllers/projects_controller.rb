class ProjectsController < ApplicationController
	http_basic_authenticate_with name: "admin", password: "admin", only: [:set_baseline]
	before_action :new_list_of_wi, except: [:tfpg_1, :tfpg_2, :tfpg_3, :skynet, :cogeco_pg]
	
	def index
		get_project
		
		# Show all Issues
		@issues = @client.Issue.jql('project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support')
	end
	
	def filtered
		get_filter
		index
		render action: :index
	end
	
	def daily_report
		get_filtered_project
		@uat_wi = get_item('uat')
		@regr_wi = get_item('regression')
		@supp_wi = get_item('support')
		# Show Critical open Issues
		@issues = @client.Issue.jql('project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support AND priority > Major AND status != Closed ORDER BY key')
		uat_ar = collect_other_bugs(@supp_wi, [])
		unless uat_ar.empty?
			@supp_issues = @client.Issue.jql('issuekey in (' + uat_ar.join(',') + ') AND status != Closed ORDER BY key')
		end
		uat_ar = collect_other_bugs(@uat_wi, uat_ar)
		uat_ar = collect_other_bugs(@regr_wi, uat_ar)
		if uat_ar.empty?
			@non_crit_issues = @client.Issue.jql('project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support AND priority < Critical AND status != Closed ORDER BY key')
		else
			@non_crit_issues = @client.Issue.jql('project = UMKBW AND issuekey NOT in (' + uat_ar.join(',') + ') AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support AND priority < Critical AND status != Closed ORDER BY key')
		end
		@known_issues = []
		unless @regr_wi.nil?
			ar = []
			@regr_wi.fields['subtasks'].each do |bug|
				ar << bug['key']
			end
			if ar.size > 0
				@regr_issues = @client.Issue.jql('project = UMKBW AND issuekey in (' + ar.join(',') + ') ORDER BY key')
				@regr_issues.each { |bug| @known_issues << bug.key }
			end
		end
		@versions = []
		@wi.each do |issue|
			version = issue.fields['fixVersions'][0]['name']
			@versions << version unless @versions.include? version
		end
		
		@z = @issues.select { |i| !(@known_issues.include? i.key) }.size
		@issues = [] if @z == 0
		
		@week_issues = get_issues('project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support AND updatedDate > startOfWeek(-1w) ORDER BY key')
	end
	
	def set_baseline
		redir_to = params[:go]
		if redir_to == 'cogeco_pg'
			get_cogeco_pg_tasks
			@qa_stories.each do |issue|
				save_baseline(issue, true)
			end
			redirect_to cogeco_pg_path
		else
			get_filtered_project
			@wi.each do |issue|
				unless @filter.include? issue.key
					save_baseline(issue)
				end
			end
			redirect_to daily_report_path
		end
	end
	
	def get_issues_dynamics
		@client = get_jira
		@all_issues = get_issues('project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support ORDER BY key')
		update_issues_with_changelog(@all_issues)
	end
	
	def issues_dynamics
		session['error'] = nil
		@client = get_jira
		@jql = params[:jql]
		new_jql = false
		if @jql.nil?
			#@jql_a = JFilter.order(updated_at: :desc).limit(1).to_a
			#if @jql_a.empty?
			#	@jql = 'project = UMKBW AND issuetype = Bug AND fixVersion in (unreleasedVersions()) AND fixVersion != Support'
			#else
			#	@jql = @jql_a[0]['body']
			#end
		else
			j_filter = JFilter.where('body' => @jql).first
			if j_filter.nil?
				new_jql = true
			else
				j_filter.touch
			end
		end
		@weeks = (params[:weeks] || 2).to_i
		if @jql.nil?
			@all_issues = []
		else
			@jql_tail = " and updated > \"-#{7*@weeks + Time.now.wday}d\" ORDER BY key" if !@jql.downcase.include?(' updated ') && !@jql.downcase.include?('order by')
			@all_issues = get_issues_with_changelog(@jql + @jql_tail.to_s)
		end
		#@all_issues = get_issues(@jql + @jql_tail.to_s)
		#update_issues_with_changelog(@all_issues)
		if new_jql && @all_issues.size > 0
			j_filter = JFilter.new('body' => @jql)
			j_filter.save!
		end
		@history_filters = JFilter.all
		@page_title = 'Reopened Issues'
	end
	
	def tfpg_1
		@client = get_jira
		@jql = params[:jql]
		if @jql.nil?
			@all_issues = []
		else
			@all_issues = get_issues(@jql.to_s)
			update_issues_with_changelog(@all_issues)
		end
		#@all_issues = get_issues('project = TFPG AND issuetype in (Bug, Defect, "Action Item") AND status not in (Cancelled) AND priority in (Blocker, Critical) AND (issueFunction in linkedIssuesOf("labels in (E2E_TC1_Create, E2E_TC2_Modify, E2E_TC3_Disconnect)", "is blocked by") OR issueFunction in linkedIssuesOf("labels in (E2E_TC1_Create, E2E_TC2_Modify, E2E_TC3_Disconnect)", "relates to"))')
		#update_issues_with_changelog(@all_issues)
		@page_title = 'Jira JQL Based Report'
	end
	
	def tfpg_2
		@client = get_jira
		@all_issues = get_issues('project = TFPG AND issuetype in (Defect, "Action Item") AND labels in (Project, project, SIT) AND Status not in (Cancelled) AND priority in (Blocker, Critical, Major) and created > "-30d"')
		update_issues_with_changelog(@all_issues)
	end
	
	def tfpg_3
	end
	
	def skynet
		@page_title = 'Reopened Issues'
	end
	
	def cogeco_pg
		@page_title = 'Cogeco PG'
		get_cogeco_pg_tasks
		@issues = get_issues('project = COGEDWPG AND type = Defect AND (resolution not in (Duplicate, "Not a Bug") OR resolution is EMPTY) AND priority in (blocker, critical) AND status != Closed').sort_by { |u| u.fields['priority']['id'].rjust(5,' ') + u.fields['created'][0..9] }
		@non_crit_issues = get_issues('project = COGEDWPG AND type = Defect AND (resolution not in (Duplicate, "Not a Bug") OR resolution is EMPTY) AND priority < Critical AND status != Closed').sort_by { |u| u.fields['priority']['id'].rjust(5,' ') + u.fields['created'][0..9] }
	end
	
	private
	
	def get_cogeco_pg_tasks
		@client = get_jira
		#@project = @client.Project.find('NC.PROD.Cogeco Darwin Product Gap')
		@qa_stories = get_issues('project = "NC.PROD.Cogeco Darwin Product Gap" AND type = Story AND (summary ~ QA OR reporter = seku0713) ORDER BY key').sort_by { |s| s.fields['customfield_10006'].to_s.rjust(14,' ') + s.fields['summary'] }
		task_keys = []
		@qa_stories.each do |story|
			story.subtasks.each do |subtask|
				task_keys << subtask['key']
			end
		end
		@qa_tasks = get_issues("issuekey in (#{task_keys.join(',')})")
	end
	
	def save_baseline(issue, is_story = false)
		get_stat(issue, nil, is_story)
		r = LastReport.new
		r.issue = issue.key
		r.total = @stat[0]
		r.passed = @stat[1]
		r.failed = @stat[2]
		r.inprogress = @stat[3]
		r.p_executed = @stat[4]
		r.p_passed = @stat[5]
		r.save!
	end
	
	def get_item(opt_name)
		uat_wi_key = Option.where('key' => opt_name).first
		unless uat_wi_key.nil?
			wi_key = uat_wi_key['option']
			@client.Issue.jql("project = UMKBW AND issuekey = '#{wi_key}'").first unless wi_key.nil?
		end
	end
	
	def authenticate
		authenticate_or_request_with_http_basic do |username, password|
			username == "admin" && password == "admin"
		end
	end
	
	def collect_other_bugs(a_wi, uat_ar)
		unless a_wi.nil?
			a_wi.fields['subtasks'].each do |bug|
				uat_ar << bug['key']
			end
		end
		uat_ar
	end
	
	def new_list_of_wi
		session[:filtered_list] = nil
		session[:full_list] = nil
	end
end
