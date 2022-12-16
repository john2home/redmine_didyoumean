class RedmineDidyoumeanHookListener < Redmine::Hook::ViewListener
    render_on(:view_issues_form_details_bottom,
              :partial => 'issues/redmine_didyoumean_injected')
end
