require 'ransack/search'

module Ransack
  Search.class_eval do
    def initialize(object, params = {}, options = {})
      params ||= {}
      @context = Context.for(object, options)
      @context.auth_object = options[:auth_object]
      @base = Nodes::Grouping.new(@context, options[:grouping] || 'and')
      build(params.with_indifferent_access)
    end
  end
end