module RansackUI
  module ViewHelpers
    def ransack_search_form(options={})
      render 'ransack/search', :options => options
    end

    def link_to_add_fields(name, f, type, options={})
      new_object = f.object.send "build_#{type}"
      fields = f.send("#{type}_fields", new_object, :child_index => "new_#{type}") do |builder|
        render "ransack/#{type.to_s}_fields", :f => builder, :options => options
      end
      link_to name, nil, :class => "add_fields", "data-field-type" => type, "data-content" => "#{fields}"
    end

    def link_to_remove_fields(name, f)
      link_to image_tag('delete.png', :size => '16x16', :alt => name), nil, :class => "remove_fields"
    end
  end
end
