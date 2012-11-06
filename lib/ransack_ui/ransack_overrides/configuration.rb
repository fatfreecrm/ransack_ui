require 'ransack/configuration'

module Ransack
  Configuration.class_eval do
    # Set default predicate options for predicate_select in form builder
    # This is ignored if any options are passed
    def default_predicates=(options)
      self.options[:default_predicates] = options
    end
  end
end