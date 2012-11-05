require 'ransack/adapters/active_record/base'

module Ransack
  module Adapters
    module ActiveRecord
      module Base
        # Return array of attributes with [name, type]
        # (Default to :string type for ransackers)
        def ransackable_attributes(auth_object = nil)
          columns.map{|c| [c.name, c.type] } +
          _ransackers.keys.map {|k| [k, :string] }
        end
      end
    end
  end
end