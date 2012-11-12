require 'ransack/nodes'

# Add Chronic parsing to date and time casting
module Ransack
  module Nodes
    Value.class_eval do
      def cast_to_date(val)
        if val.is_a?(String)
          Chronic.parse(val).in_time_zone.to_date rescue nil
        elsif val.respond_to?(:to_date)
          val.to_date rescue nil
        else
          y, m, d = *[val].flatten
          m ||= 1
          d ||= 1
          Date.new(y,m,d) rescue nil
        end
      end

      def cast_to_time(val)
        if val.is_a?(Array)
          Time.zone.local(*val) rescue nil
        else
          unless val.acts_like?(:time)
            val = val.is_a?(String) ? Chronic.parse(val) : val.to_time rescue nil
          end
          val.in_time_zone rescue nil
        end
      end
    end
  end
end