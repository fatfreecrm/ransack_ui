require 'ransack/search'

module Ransack
  Search.class_eval do
    def initialize(object, params = {}, options = {})
      params = {} unless params.is_a?(Hash)
      (params ||= {})
      .delete_if { |k, v| [*v].all? { |i| i.blank? && i != false } }
      @context = Context.for(object, options)
      @context.auth_object = options[:auth_object]
      @base = Nodes::Grouping.new(@context, options[:grouping] || 'and')
      @scope_args = {}
      build(params.with_indifferent_access)
    end
  end
end
