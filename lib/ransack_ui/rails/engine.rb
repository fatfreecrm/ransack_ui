require 'ransack_ui/view_helpers'

module RansackUI
  module Rails
    class Engine < ::Rails::Engine
      initializer "ransack_ui.view_helpers" do
        ActionView::Base.send :include, ViewHelpers
      end

      initializer :assets do
        ::Rails.application.config.assets.precompile += %w( delete.png )
      end
    end
  end
end
