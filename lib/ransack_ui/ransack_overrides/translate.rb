require 'ransack/translate'

module Ransack
  Translate.class_eval do
    def self.attribute(key, options = {})
      unless context = options.delete(:context)
        raise ArgumentError, "A context is required to translate attributes"
      end

      original_name = key.to_s
      base_class = context.klass
      base_ancestors = base_class.ancestors.select { |x| x.respond_to?(:model_name) }
      predicate = Predicate.detect_from_string(original_name)
      attributes_str = original_name.sub(/_#{predicate}$/, '')
      attribute_names = attributes_str.split(/_and_|_or_/)
      combinator = attributes_str.match(/_and_/) ? :and : :or
      defaults = base_ancestors.map do |klass|
        :"ransack.attributes.#{klass.model_name.demodulize.downcase.underscore}.#{original_name}"
      end

      translated_names = attribute_names.map do |attr|
        attribute_name(context, attr, options[:include_associations])
      end

      interpolations = {}
      interpolations[:attributes] = translated_names.join(" #{Translate.word(combinator)} ")

      if predicate
        defaults << "%{attributes} %{predicate}"
        interpolations[:predicate] = Translate.predicate(predicate)
      else
        defaults << "%{attributes}"
      end

      defaults << options.delete(:default) if options[:default]
      options.reverse_merge! :count => 1, :default => defaults
      I18n.translate(defaults.shift, options.merge(interpolations))
    end
  end
end