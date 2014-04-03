require 'cql'


# $cql =  ConnectionPool::Wrapper.new(size: 10, timeout: 3) { 
#   Cql::Client::connect(Rails.application.config.cassandra)
# }
$cql =  Cql::Client::connect(Rails.application.config.cassandra)

Resque.after_fork = proc do
  puts "Connecting to C*...."
  $cql =  Cql::Client::connect(Rails.application.config.cassandra)
  puts "Connected to C*"
end
