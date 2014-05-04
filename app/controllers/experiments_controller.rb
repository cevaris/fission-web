class ExperimentsController < InheritedResources::Base
  respond_to :html, :json
  actions :all, except: [:new, :edit]
  before_filter :restrict_access, only: :create

  def index
    if current_app and current_client
      @experiments = current_app.experiments
      data = []
      @experiments.each do |experiment|
        if experiment.variations.count > 0
          variation = Variation.includes(:clients).where(clients: { id: current_client.id }, experiment_id: experiment.id).first
          unless variation
            variation = experiment.variations.sample
            variation.assignments.build client: current_client
            variation.save
          end
          data << { name: experiment.name, variation: variation.name }
        end
      end
      render json: data.to_json
    else
      index!
    end
  end

  def show
    @experiment = Experiment.find params[:id]

    @counts_json = []
    @experiment.variations.each do |variation|
      # Rails.logger.info variation.participants
      # Rails.logger.info variation.converted
      # Rails.logger.info variation.measure
      @counts_json << {abtest: variation.name,'Complete' => variation.converted,'Total'=>variation.participants}
    end

    @counts_json = @counts_json.to_json 
    Rails.logger.info @counts_json
  end

  def complete
    @experiment = Experiment.find params[:id]

    outcome = ABTest.complete(@experiment.variations,@experiment.outcome)
    if outcome
      @experiment.outcome = outcome
      @experiment.is_active = false
      @experiment.save
    end

    redirect_to @experiment
  end

  def create
    @experiment = current_app.experiments.build permitted_params
    create! do |success, failure|
      success.json do
        variation = Variation.includes(:clients).where(clients: { id: current_client.id }, experiment_id: @experiment.id).first
        unless variation
          variation = @experiment.variations.find_by_name params[:experiment][:variations_attributes].first[:name]
          variation.assignments.build client: current_client
          variation.save
        end
      end
    end
  end

  def permitted_params
    params.require(:experiment).permit(:name, variations_attributes: [:name])
  end
end