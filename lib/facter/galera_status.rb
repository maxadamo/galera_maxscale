Facter.add('galera_joined_exist') do
  setcode do
    require 'net/http'
    uri = URI('http://localhost:9200/')
    res = Net::HTTP.get_response(uri)
    res.code
  end
end
