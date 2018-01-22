Facter.add('galera_joined_exist') do
  setcode do
    file_name = '/root/.JOINED'
    if File.file?(file_name)
      true
    else
      false
    end
  end
end
