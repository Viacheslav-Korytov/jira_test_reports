json.array!(@options) do |option|
  json.extract! option, :id, :key, :option
  json.url option_url(option, format: :json)
end
