Facter.add('galera_status') do
  setcode do
    begin
      Socket.tcp("localhost", 9200, connect_timeout: 5) {}
    rescue
      require 'net/http'
      uri = URI('http://localhost:9200/')
      Net::HTTP.get_response(uri).code
    ensure
      'UNKNOWN'
    end
  end
end
