module RansackUI
  module ViewHelpers
    def ransack_ui_search(options)
      render 'ransack_ui/search', :options => options
    end

    def link_to_add_fields(name, f, type)
      new_object = f.object.send "build_#{type}"
      fields = f.send("#{type}_fields", new_object, :child_index => "new_#{type}") do |builder|
        render "ransack_ui/#{type.to_s}_fields", :f => builder
      end
      link_to nil, :class => "add_fields btn btn-small btn-primary", "data-field-type" => type, "data-content" => "#{fields}" do
        "<i class=\"icon-plus-sign icon-white\"></i> #{name}".html_safe
      end
    end

    def link_to_remove_fields(name, f)
      link_to image_tag('ransack_ui/delete.png', :size => '16x16', :alt => name), nil, :class => "remove_fields"
    end
  end
end
