require 'ransack/helpers/form_builder'

module Ransack
  module Helpers
    FormBuilder.class_eval do
      def attribute_select(options = {}, html_options = {})
        raise ArgumentError, "attribute_select must be called inside a search FormBuilder!" unless object.respond_to?(:context)
        options[:include_blank] = true unless options.has_key?(:include_blank)

        # Set default associations set on model with 'has_ransackable_associations'
        if options[:associations].nil?
          options[:associations] = object.context.klass.ransackable_associations
        end

        bases = [''] + association_array(options[:associations])
        if bases.size > 1
          @template.select(
            @object_name, :name,
            @template.grouped_options_for_select(attribute_collection_for_bases(bases)),
            objectify_options(options), @default_options.merge(html_options)
          )
        else
          collection = object.context.searchable_attributes(bases.first).map do |c|
            [
              attr_from_base_and_column(bases.first, c),
              Translate.attribute(attr_from_base_and_column(bases.first, c), :context => object.context)
            ]
          end
          @template.collection_select(
            @object_name, :name, collection, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        end
      end

      def predicate_select(options = {}, html_options = {})
        options = Ransack.options[:default_predicates] || {} if options.blank?

        options[:compounds] = true if options[:compounds].nil?
        keys = predicate_keys(options)
        # If condition is newly built with build_condition(),
        # then replace the default predicate with the first in the ordered list
        @object.predicate_name = keys.first if @object.default?
        @template.collection_select(
          @object_name, :p, keys.map {|k| [k, Translate.predicate(k)]}, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
        )
      end

      def attribute_collection_for_bases(bases)
        bases.map do |base|
          begin
          [
            Translate.association(base, :context => object.context),
            object.context.searchable_attributes(base).map do |c, type|
              attribute = attr_from_base_and_column(base, c)
              [
                Translate.attribute(attribute, :context => object.context),
                attribute,
                {:'data-type' => type}
              ]
            end
          ]
          rescue UntraversableAssociationError => e
            nil
          end
        end.compact
      end
    end
  end
end