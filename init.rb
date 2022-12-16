Redmine::Plugin.register :redmine_didyoumean do
  name 'Did You Mean?'
  author 'Alessandro Bahgat, Mattia Tommasone and Matthias Piela'
  description 'A plugin to search for duplicate issues before opening them.'
  version '2.0.0'
  url 'http://www.github.com/abahgat/redmine_didyoumean'
  author_url 'http://abahgat.com/'
  requires_redmine version_or_higher: '5'

  default_settings = {
    'show_only_open' => '1',
    'project_filter' => '1',
    'min_word_length' => '2',
    'limit' => '5',
    'start_search_when' => '0',
  }

  settings default: default_settings, partial: 'settings/redmine_didyoumean_settings'
end

require_relative 'lib/redmine_didyoumean_hook_listener'
