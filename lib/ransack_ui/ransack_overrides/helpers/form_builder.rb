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
          klass = object.context.traverse(base)
          foreign_keys = klass.reflect_on_all_associations.select(&:belongs_to?).
                           map_to({}) {|r, h| h[r.foreign_key.to_sym] = r.class_name }
          ajax_options = Ransack.options[:ajax_options] || {}

          if base.present?
            model = object.context.traverse(base).model_name
          end

          begin
          [
            Translate.association(base, :context => object.context),
            object.context.searchable_attributes(base).map do |c, type|
              # Don't show 'id' column for base model
              next nil if base.blank? && c == 'id'

              attribute = attr_from_base_and_column(base, c)
              attribute_label = Translate.attribute(attribute, :context => object.context)

              # Set model name as label for 'id' column on that model's table.
              if c == 'id'
                foreign_klass = object.context.traverse(base).model_name
                # Check that model can autocomplete. If not, skip this id column.
                next nil unless foreign_klass.constantize._ransack_can_autocomplete
                attribute_label = I18n.translate(foreign_klass, :default => foreign_klass)
              else
                foreign_klass = foreign_keys[c.to_sym]
              end

              # Add column type as data attribute
              html_options = {:'data-type' => type}
              # Set 'base' attribute if attribute is on base model
              html_options[:'data-base'] = true if base.blank?

              if foreign_klass
                # If field is a foreign key, set up 'data-ajax-*' attributes for auto-complete
                controller = foreign_klass.tableize
                html_options[:'data-ajax-entity'] = I18n.translate(controller, :default => controller)
                if ajax_options[:url]
                  html_options[:'data-ajax-url'] = ajax_options[:url].sub(':controller', controller)
                else
                  html_options[:'data-ajax-url'] = "/#{controller}.json"
                end
                html_options[:'data-ajax-type'] = ajax_options[:type] || 'GET'
                html_options[:'data-ajax-key']  = ajax_options[:key]  || 'query'
              end
              [
                attribute_label,
                attribute,
                html_options
              ]
            end.compact
          ]
          rescue UntraversableAssociationError => e
            nil
          end
        end.compact
      end
    end
  end
end