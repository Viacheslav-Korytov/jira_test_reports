json.array!(@last_reports) do |last_report|
  json.extract! last_report, :id, :issue, :total, :passed, :failed, :inprogress, :p_executed, :p_passed
  json.url last_report_url(last_report, format: :json)
end
