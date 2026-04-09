# frozen_string_literal: true

module Flehmen
  module Tools
    class Base < FastMcp::Tool
      def call(**args)
        ActiveRecord::Base.while_preventing_writes(Flehmen.configuration.read_only_connection) do
          execute(**args)
        end
      end
    end
  end
end
