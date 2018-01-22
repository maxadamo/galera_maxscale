Facter.add('galera_status') do
  setcode do
    require 'net/http'
    uri = URI('http://localhost:9200/')
    Net::HTTP.get_response(uri).code
  end
end
