json.array!(@test_preparations) do |test_preparation|
  json.extract! test_preparation, :id, :issue, :tc_plan, :tc_date
  json.url test_preparation_url(test_preparation, format: :json)
end
