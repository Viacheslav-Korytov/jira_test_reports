class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include ProjectsHelper

	#require 'c:\RailsInstaller\Ruby1.9.3\lib\ruby\gems\1.9.1\gems\oauth-0.4.7\lib\oauth'
	#require 'c:\RailsInstaller\Ruby1.9.3\lib\ruby\gems\1.9.1\gems\jira-ruby-0.1.10\lib\jira.rb'
	require 'oauth'
	require 'jira'
	require 'thread'

	def get_jira
		opt = JSON.parse(File.read('c:\\Projects\\RoR\\TMS_options.txt')) 
		site = opt['site'] 
		#@browse_address = "#{site}/i#browse/"
		@browse_address = "#{site}/browse/"

		options = {
            :username => opt['username'],
            :password => opt['password'],
            :site     => site,
            :context_path => '',
			:rest_base_path => "/rest/api/latest",
            :auth_type => :basic
        }
		
		#File.write('c:\\Projects\\RoR\\TMS_options1.txt', options.to_json)
		
		JIRA::Client.new(options)
	end
	
	def get_filter
		@out_filter = []
		ex_opt = Option.where("key=?", 'exclude')
		ex_opt.each { |e| @out_filter << e['option'].to_s }
		@int_exclude = []
		int_ex = Option.where("key=?", 'remove from integration')
		int_ex.each { |e| @int_exclude << e['option'].to_s }
		@have_filter = true
	end
	
	def get_project
		@client = get_jira

		@project = @client.Project.find('UMKBW')
		
		# Work Items
		wi = get_issues('project = UMKBW AND issuetype = "Work Item" AND fixVersion in (unreleasedVersions()) ORDER BY key')
		if @have_filter
			@filter = @out_filter
			@wi = []
			wi.each do |issue|
				unless @filter.include? issue.key
					@wi << issue
				end
			end
		else
			@filter = []
			@wi = wi
		end
		@bugzilla = 'http://www.coraltreesystems.com/bugzilla/show_bug.cgi?id='
	end
	
	def get_filtered_project
		get_filter
		get_project
	end
	
	def get_list_of_wi(is_filtered = true)
		require 'json'
		@wi_list = []
		if is_filtered
			if session[:filtered_list]
				f = File.read(session[:filtered_list])
				@wi_list = JSON.parse(f)
				return
			end
			get_filtered_project
		else
			if session[:full_list]
				f = File.read(session[:full_list])
				@wi_list = JSON.parse(f)
				return
			end
			get_project
		end
		@wi.each do |issue|
			e = []
			e << issue.fields['summary']
			e << issue.key
			@wi_list << e
		end
		if is_filtered
			session[:filtered_list] = 'c:\\tmp\\filtered_list.tmp'
			File.write(session[:filtered_list], @wi_list.to_json)
		else
			session[:full_list] = 'c:\\tmp\\full_list.tmp'
			File.write(session[:full_list], @wi_list.to_json)
		end
	end
	
	def get_issues(jql, only_keys = false)
		mutex = Mutex.new
		arr = []
		max_results = 5
		start_at = 0
		@local_json = []
		@total_issues_number = 0
		issues = []
		session['error'] = nil
		
		Rails.logger.info("1st request to Jira - #{Time.now}")
		
		json = get_some_issues_from_jira(jql, max_results, start_at, only_keys)
		unless json.nil?
			max_results = json['issues'].size
			@total_issues_number = json['total'].to_i
			@local_json << json
			json = nil
			Rails.logger.info("Returned #{max_results} issues - #{Time.now}")
		else
			Rails.logger.error("No issues returned - #{Time.now}")
			return issues
		end
		start_at += max_results
		
		@threads_number = 0
		max_results = 10
		( 1..((@total_issues_number - start_at).to_f / max_results).ceil ).each do |i|
			arr << Thread.new do
				mutex.synchronize do
					@threads_number += 1
				end
				t_json = get_some_issues_from_jira(jql, max_results, start_at, only_keys)
				unless t_json.nil?
					mutex.synchronize do
						@local_json << t_json
						@threads_number -= 1
						Rails.logger.info("Thread: Returned #{t_json['issues'].size} issues - #{Time.now}")
					end
				end
				t_json = nil
			end
			Rails.logger.info("Thread #{arr.size} created - #{Time.now}")
			begin
				sleep 0.3
			end while @threads_number > 30
			if !only_keys
				while @threads_number > 3 do
					sleep 0.5
				end
				#arr.each { |t| t.join }
			end
 			start_at += max_results
		end
		
		arr.each { |t| t.join }
		
		Rails.logger.info("All issues returned - #{Time.now}")
		
		@local_json.each do |js|
			issues << js['issues'].map { |is| @client.Issue.build(is) }
		end
		@local_json = nil
		issues.flatten.sort_by { |i| i.key }
	end

	def get_some_issues_from_jira(jql, max_res = 45, strt_at = 0, only_keys = false)
        @url = @client.options[:rest_base_path] + "/search?jql=#{CGI.escape(jql)}"
        @url += "&startAt=#{strt_at}&maxResults=#{max_res}" if max_res > 0
		@url += "&fields=key" if only_keys
		n_att = 0
		begin
			response = @client.get(@url)
		rescue Exception => e
			n_att += 1
			Rails.logger.error(e.to_s)
			session['error'] = e.to_s
			sleep 5
			retry if n_att < 5
		end
        response.nil? ? nil : JSON.parse(response.body)
	end
	
	def get_issues_with_changelog(jql)
		a = get_issues(jql, true)
		update_issues_with_changelog(a)
		a
	end

	
	def get_changelog(issue_key)
        url = @client.options[:rest_base_path] + "/issue/#{issue_key}?expand=changelog"
		n_att = 0
		begin
			response = @client.get(url)
		rescue Exception => e
			n_att += 1
			Rails.logger.error(e.to_s)
			sleep 5
			retry if n_att < 20
		end
        response.nil? ? nil : JSON.parse(response.body)
	end
	
	def update_issues_with_changelog(issues)
		mutex = Mutex.new
		arr = []
		@changelog_updates = []
		@threads_number = 0
		issues.each do |issue|
			arr << get_history_for_one_issue(issue.key, mutex)
			#Rails.logger.info("Thread #{arr.size} on History of #{issue.key} created - #{Time.now}")
			begin
				sleep 0.1
			end while @threads_number > 30
		end
		arr.each { |t| t.join }
		Rails.logger.info("All Histories returned - #{Time.now}")
		@changelog_updates.sort_by! { |u| u['key'] }
	end
	
	def get_history_for_one_issue(issue_key, mutex)
		Thread.new do
			mutex.synchronize do
				@threads_number += 1
			end
			ch_log = get_changelog(issue_key)
			unless ch_log.nil?
				ch_log_update = {}
				ch_log_update['key'] = issue_key
				ch_log_update['status'] = [] << [ 'Created', ch_log['fields']['created'][0..9] ]
				ch_log_update['labels'] = []
				ch_log['changelog']['histories'].each do |history|
					history['items'].each do |item|
						if item['field'] == 'status'
							ch_log_update['status'] << [ item['toString'], history['created'][0..9] ]
						elsif item['field'] == 'labels'
							ch_log_update['labels'] << [ item['toString'], history['created'][0..9] ]
						end
					end
				end
				mutex.synchronize do
					@changelog_updates << ch_log_update
					@threads_number -= 1
					#Rails.logger.info("History returned for #{issue_key} - #{Time.now}")
				end
			end
		end
	end
	
end

class JIRA::Resource::Issue

  def self.jql(client, jql, max_results = 45, start_at = 0)
        url = client.options[:rest_base_path] + "/search"
		bb = Hash.new
		bb['jql'] = jql
		bb['maxResults'] = max_results
		bb['startAt'] = start_at
		#bb['fields'] = "key,summary,priority,status,created,assignee,customfield_10100,customfield_10017"
		body = bb.to_json
#		+ CGI.escape(jql)
        #url += CGI.escape("&maxResults=30")
        #url += CGI.escape("&fields=#{fields.join(",")}") if fields
        response = client.post(url, body)
        json = parse_json(response.body)
		client.set_total_number(json['total'])
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
  end
  
end

class JIRA::Client
	def set_total_number(n)
		@total_number = n.to_i
	end
	
	def get_total_number
		@total_number
	end
end