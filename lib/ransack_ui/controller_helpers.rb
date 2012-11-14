module RansackUI
  module ControllerHelpers
    # Builds @ransack_search object from params[:q]
    # Infers model class from controller name.
    #
    # Should be used as a before_filter, e.g.:
    #    before_filter :load_ransack_search, :only => :index
    def load_ransack_search
      klass = controller_name.classify.constantize
      @ransack_search = klass.search(params[:q])
      @ransack_search.build_grouping unless @ransack_search.groupings.any?
    end
  end
end
