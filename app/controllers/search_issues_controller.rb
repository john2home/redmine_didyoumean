class SearchIssuesController < ApplicationController

  before_action :find_project, :get_query, :get_project_filter, :get_limit

  def index
    get_results
    render :json => results_to_json
  end

  private

  def get_results
    if @query.blank?
      @query = ""
      @count = 0
      @issues = []
    else
      get_search_method
      @issues = @results.first
      @count = @results.last
    end
  end

  def results_to_json
    {
      :total => @count,
      :issues => @issues.map do |i|
        {
          :id => i.id,
          :tracker_name => i.tracker.name,
          :subject => i.subject,
          :status_name => i.status.name,
          :project_name => i.project.name
        }
      end
    }
  end

  def get_search_method
#    @results = search_class.new.search @project_tree, params[:issue_id], @query, @limit
    @results = search @project_tree, params[:issue_id], @query, @limit
  end

 # def search_class
 #   case Setting.plugin_redmine_didyoumean['search_method']
 #   when "0"
 #     SqlSearch
 #   when "1"
 #     ThinkingSphinxSearch
 #   else
 #     raise 'There is no search method selected!'
 #   end
 # end

  def get_project_filter
    case Setting.plugin_redmine_didyoumean['project_filter']
    when '3'
      @project_tree = @project ? @project.root.self_and_descendants.active : nil
    when '2'
      @project_tree = Project.all
    when '1'
      @project_tree = @project ? @project.self_and_descendants.active : nil
    when '0'
      @project_tree = [@project]
    else
      logger.warn "Unrecognized option for project filter: [#{Setting.plugin_redmine_didyoumean['project_filter']}], skipping"
    end
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  end

  def get_query
    @query = params[:query] || ""
    @query.strip!
  end

  def get_limit
    @limit = Setting.plugin_redmine_didyoumean['limit'] || 5 if @limit.nil? or @limit.empty?
  end

#########################

  def search project_tree, issue_id, query, limit
    initialize2
    set_variables query
    get_conditions project_tree, issue_id
    set_results limit
  end

  def initialize2
    @query = Issue.visible.order("issues.id DESC")

    all_words = true
    @min_length = Setting.plugin_redmine_didyoumean['min_word_length'].to_i
    @separator = all_words ? ' AND ' : ' OR '
  end

  def set_variables query
    @variables = query.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    @variables = @variables.uniq.select {|w| w.length >= @min_length }
    @variables.slice! 5..-1 if @variables.size > 5
    @variables.map! {|cur| '%' + cur +'%'}
  end

  def project_condition project_tree
    scope = project_tree.select {|p| User.current.allowed_to?(:view_issues, p)}.collect(&:id)
    @query = @query.where(project_id: scope)
  end

  def only_open_condition
    valid_statuses = IssueStatus.where("is_closed <> ?", true).collect(&:id)
    @query = @query.where(status_id: valid_statuses)
  end

  def edited_condition issue_id
    @query = @query.where('issues.id != ?', issue_id)
  end

  def get_conditions project_tree, issue_id
    variables_condtions
    project_condition(project_tree) if project_tree
    only_open_condition if Setting.plugin_redmine_didyoumean['show_only_open'] == "1"
    edited_condition(issue_id) unless issue_id.nil? || issue_id.blank?
  end

  def variables_condtions
    @variables.each do |v|
      @query = @query.where('lower(subject) like lower(?)', v)
    end
  end

  def set_results limit
    issues = @query.limit(limit)
    count = @query.count
    return issues, count
  end

end
