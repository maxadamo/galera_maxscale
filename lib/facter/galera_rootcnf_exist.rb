Facter.add('galera_rootcnf_exist') do
  setcode do
    file_name = '/root/.my.cnf'
    if File.file?(file_name)
      true
    else
      false
    end
  end
end
