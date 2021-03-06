module V1
  ###
  # Spin Candidates controller
  # Provides actions on the Spin Candidates
  #
  ##
  class SpinCandidatesController < ApiController
    before_action :authenticate_user! # Only authenticated values are valid

    ###
    # Index (search: string - optional )
    # Provides an index of all spins in the system
    # TODO If you provide a search team, it will return those spins mathing the search
    # users/<user_id>/spins Get all spins of a user
    # spins?query=<value>  Look spins include value in the name
=begin
  @api {get} /spin_candidates Request list of spin_candidates for the user
  @apiVersion 1.0.0
  @apiName GetSpinCandidate
  @apiGroup SpinCandidate
  @apiPermission user
  @apiSuccess {String} version Version of the API
  @apiSuccess {Object[]} providers Authentication endpoints
  @apiSuccess {String=["github"]} providers.type Type of provider oauth
  @apiSuccess {Boolean} providers.enabled Whether the provide is enabled or not
  @apiSuccess {String} providers.id_application Id of the application in the oauth provider.
  @apiSuccess {String} providers.server Server Address
  @apiSuccess {String} providers.version API Prefix
  @apiSuccess {Boolean} providers.verify Does it need verify?
=end
    def index
      @spins = SpinCandidate.where(user_id: current_user)
      @spins = @spins.where('name ILIKE ?', "%#{params[:query]}%") if params[:query]
      @spins = @spins.order("#{params[:sort]} #{params[:order] || 'DESC'}") if params[:sort]
      if @spins.count.positive?
        return_response @spins, :ok, {}
      else
        render status: :no_content
      end
    end

    ###
    # Show (id: identification of the spin)
    # Provides a view of the Spin Candidate
    #
    # @params id: integer id of the spin candidate
    def show
      @spin = SpinCandidate.find_by(user_id: current_user.id, id: params[:id])
      unless @spin
        render_error_exchange(:spin_candidate_not_found, :not_found)
        return
      end
      return_response @spin, :ok, {}
    end

    ###
    # Refresh
    # Authenticated only
    # Refresh the list of providers for the user.
    # Connects to github, gets all repos of the user, and search for spins
    #
    def refresh
      user = current_user.admin? ? User.find(params[:user_id]) : current_user
      if user.nil?
        render json: { error: 'No user found' }, status: :not_found
        return
      end
      job = RefreshSpinCandidatesJob.perform_later(user: user, token: request.headers['HTTP_X_USER_TOKEN'])
      render json: { data: job.job_id, metadata: { queue: job.queue_name, priority: job.priority } }, status: :accepted
    end

    # Validates the SpinCandidate
    # @returns true | false
    # updates the log
    def validate
      # Create Spin with metadata
      # Validate the Spin
      # Write result in log
      # Return true or false
      sc = SpinCandidate.find(params[:spin_candidate_id])
      if sc
        unless current_user == sc.user
          render_error_exchange(:spin_not_owner, :not_allowed)
          return
        end
        spin = sc.spin || Spin.new(full_name: sc.full_name, user: sc.user, spin_candidate: sc)
        if spin.check current_user
          return_response sc, :ok, {}
        else
          render_error_exchange(:spin_candidate_not_validated, :not_found, {log: sc.validation_log})
        end
      else
        render_error_exchange(:spin_candidate_not_found, :not_found)
      end
    end

    # Publish the SpinCandidate into a Spin
    # @returns :ok or :error
    def publish
      #puts "User is"+ current_user.inspect
      sc = SpinCandidate.find(params[:spin_candidate_id])
      spin = sc.spin || Spin.new(full_name: sc.full_name, user: sc.user, spin_candidate: sc)
      unless current_user == sc.user
        render_error_exchange(:spin_candidate_not_owner, :not_allowed)
        return
      end
      if sc
        if sc.publish_spin user: current_user
          return_response sc, :ok, {}
        else
          render_error_exchange(:spin_candidate_not_validated, :precondition_failed)
        end
      else
        render_error_exchange(:spin_candidate_not_found, :not_found)
      end
      # If valid create or update the Spin
      # If not valid, the log should be updated.
    end

    def unpublish
      sc = SpinCandidate.find(params[:spin_candidate_id])
      if sc.spin
        if sc.unpublish
          return_response sc, :ok, {}
        else
          render_error_exchange(:spin_candidate_not_published, :precondition_failed)
        end
      else
        render_error_exchange(:spin_candidate_not_published, :not_found)
      end
    end
  end
end
