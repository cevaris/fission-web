# == Schema Information
#
# Table name: clients
#
#  app_id        :long
#  experiment_id :long
#  variation_id  :long
#  success_count :counter
#  total_count   :counter
#
require 'cql'

class VariationCount

  # Longs
  attr_accessor :app_id, :experiment_id, :variation_id
  # Counters
  attr_accessor :success_count, :total_count



  def initialize(params={app_id:1, experiment_id:1, variation_id:1})
    params.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def keyspace
    'fission_dev'
  end

  def column_family
    'variation_count'
  end







  # Save if the user successfully saw a variation
  def save()
    connect() unless @success_statement
    @statement.execute(self.app_id, self.experiment_id, self.variation_id)
  end

  # Save if the user successfully got to the goal of the experiment
  def save_success()
    connect() unless @success_statement
    @success_statement.execute(self.app_id, self.experiment_id, self.variation_id)
  end

  def get(params=nil)
    connect() unless @success_statement
    
    if params
      @select_statement.execute(params[:app_id], params[:experiment_id], params[:variation_id])
    else
      @select_statement.execute(self.app_id, self.experiment_id, self.variation_id)
    end
  end




  def counts()
    counts = {total_count: 0, success_count: 0}

    connect() unless @success_statement
    exp_vars = @select_statement.execute(self.app_id, self.experiment_id, self.variation_id)

    if exp_vars
      exp_vars.each do |row|
        counts[:total_count]   += row['total_count']
        counts[:success_count] += row['success_count']
      end
    end
    return counts[:total_count], counts[:success_count]
  end


  def self.counts(variation)
    vc = VariationCount.new
    counts = {total_count: 0, success_count: 0}
    query = {
      app_id: variation.experiment.app.id,
      experiment_id: variation.experiment.id,
      variation_id: variation.id
    }

    exp_vars = vc.get(query)

    if exp_vars
      exp_vars.each do |row|
        counts[:total_count]   += row['total_count']
        counts[:success_count] += row['success_count']
      end
    end
    return counts[:total_count], counts[:success_count]
  end

  private 

  def connect()
    @options = Rails.application.config.cassandra
    @client = Cql::Client::connect(@options)

    @select_statement = @client.prepare(%{
      SELECT app_id, experiment_id, variation_id, success_count, total_count 
        FROM #{keyspace()}.#{column_family()}
        WHERE app_id=? AND experiment_id=? AND variation_id=?
    })
    @success_statement = @client.prepare(%{
      UPDATE #{keyspace()}.#{column_family()}
        SET success_count = success_count + 1
        WHERE app_id=? AND experiment_id=? AND variation_id=?
    })
    @statement = @client.prepare(%{
      UPDATE #{keyspace()}.#{column_family()}
        SET total_count = total_count + 1
        WHERE app_id=? AND experiment_id=? AND variation_id=?
    })
  end
end