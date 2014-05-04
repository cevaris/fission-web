require 'net/http'
require 'json'
require 'ab_test'

# require "#{Rails.root}/app/helpers/cassandra_helper"
# include CassandraHelper

namespace :split do


  desc "Check running Applications"
  task :generate => :environment do

    app = App.first
    exp = app.experiments.sample
    winner_var = exp.variations.sample

    record = {app_id: app.id, experiment_id: exp.id}
    loop do

      var = exp.variations.sample

      samples = [false, false, false, true, false]
      samples = [false, false, true, true, false] if var.id == winner_var.id

      record[:variation_id]  = var.id

      vc = VariationCount.new(record)

      if samples.sample
        puts "insert_success for #{var.id}"
        vc.save_success()
      else
        puts "insert_fail for #{var.id}"
        vc.save()
      end
      # sleep(1.0)
    end
  end


  desc "Compute Split test on all experiments"
  task :process => :environment do

    experiment = Experiment.all.sample

    results = ABTest.score(experiment.variations,experiment.outcome)
    experiment.best = results.best
    experiment.base = results.base
    experiment.worst = results.worst
    experiment.choice = results.choice
    experiment.save
    results.variations.select(&:save)
  
  end


  desc "Compute Split test on all experiments"
  task :complete => :environment do

    experiment = Experiment.all.sample

    outcome = ABTest.complete(experiment.variations,experiment.outcome)
    if outcome
      experiment.outcome = outcome
      experiment.is_active = false
      experiment.save
    end
      
  end

end