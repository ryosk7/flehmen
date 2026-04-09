# frozen_string_literal: true

require "fast_mcp"
require_relative "synapse/version"
require_relative "synapse/configuration"
require_relative "synapse/model_registry"
require_relative "synapse/field_filter"
require_relative "synapse/query_builder"
require_relative "synapse/serializer"
require_relative "synapse/tools/list_models_tool"
require_relative "synapse/tools/describe_model_tool"
require_relative "synapse/tools/find_record_tool"
require_relative "synapse/tools/search_records_tool"
require_relative "synapse/tools/count_records_tool"
require_relative "synapse/tools/show_associations_tool"
require_relative "synapse/tools/execute_query_tool"
require_relative "synapse/resources/schema_overview_resource"

module Synapse
  class << self
    attr_accessor :model_registry
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def boot!
      @model_registry = ModelRegistry.new(configuration)
      @model_registry.discover!
    end

    def start_server!
      server = build_server
      server.start
    end

    def mount_in_rails(app, options = {})
      boot! unless model_registry

      opts = {
        name: "synapse",
        version: Synapse::VERSION,
        path_prefix: options.delete(:path_prefix) || "/mcp"
      }.merge(options)

      FastMcp.mount_in_rails(app, opts) do |server|
        register_tools(server)
        register_resources(server)
      end
    end

    private

    def build_server
      server = FastMcp::Server.new(
        name: "synapse",
        version: Synapse::VERSION
      )
      register_tools(server)
      register_resources(server)
      server
    end

    def register_tools(server)
      server.register_tool(Tools::ListModelsTool)
      server.register_tool(Tools::DescribeModelTool)
      server.register_tool(Tools::FindRecordTool)
      server.register_tool(Tools::SearchRecordsTool)
      server.register_tool(Tools::CountRecordsTool)
      server.register_tool(Tools::ShowAssociationsTool)
      server.register_tool(Tools::ExecuteQueryTool) if configuration.enable_raw_sql
    end

    def register_resources(server)
      server.register_resource(Resources::SchemaOverviewResource)
    end
  end
end
