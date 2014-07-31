require_dependency 'issues_controller'

module DefaultCustomQuery
  module IssuesControllerPatch
    unloadable

    extend ActiveSupport::Concern

    included do
      unloadable

      before_filter :with_default_query, only: [:index], if: :default_query_module_enabled?
      alias_method_chain :retrieve_query_from_session, :default_custom_query
    end

    def with_default_query
      case
      when params[:query_id].present?
        # Nothing to do
      when api_request?
        # Nothing to do
      when show_all?
        params[:set_filter] = 1
      when filter_applied?
        # Nothing to do
      when filter_cleared?
        apply_default_query!
      when session[:query]
        apply_default_query! unless session[:query][:id]
      else
        apply_default_query!
      end
    end

    def retrieve_query_from_session_with_default_custom_query
      if session[:query]
        retrieve_query_from_session_without_default_custom_query
      elsif default_query_module_enabled?
        @query = find_default_query
      end
    end

    private

    def find_default_query
      ProjectsDefaultQuery.find_by_project_id(@project).try(:query)
    end

    def apply_default_query!
      default_query = find_default_query
      if default_query
        params[:query_id] = default_query.id
      end
    end

    def filter_applied?
      params[:set_filter] && params.key?(:op) && params.key?(:f)
    end

    def filter_cleared?
      params[:set_filter] && [:op, :f].all? {|k| !params.key?(k) }
    end

    def show_all?
      params[:without_default]
    end

    def default_query_module_enabled?
      @project.module_enabled?(:default_custom_query)
    end
  end
end

IssuesController.send :include, DefaultCustomQuery::IssuesControllerPatch
