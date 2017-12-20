# coding: utf-8
@app_name = app_name

def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

def say_custom(tag, text)
  say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}"
end

def whisper_ask_wizard(question)
  ask "\033[1m\033[36m" + ("choose").rjust(10) + "\033[0m" + "  #{question}"
end

def multiple_choice(question, choices)
  say_custom('option', "\033[1m\033[36m" + "#{question}\033[0m")
  values = {}
  choices.each_with_index do |choice, i|
    values[(i + 1).to_s] = choice
    say_custom( (i + 1).to_s + ')', choice.to_s.capitalize )
  end
  answer = whisper_ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

def search_attrs(attributes)
  attrs_with_type = attributes.group_by(&:type)
  {
    text: [
        attrs_with_type[:string],
        attrs_with_type[:text]
      ].flatten.compact.map(&:name),
    date:
      (attrs_with_type[:date] || []).map{ |attr|
        ["#{attr.name}_from", "#{attr.name}_to"]
      }.flatten,
    date_time: [
        attrs_with_type[:date_time],
        attrs_with_type[:time]
      ].flatten.compact.map{ |attr|
        ["#{attr.name}_from", "#{attr.name}_to"]
      }.flatten,
    integer:
      (attrs_with_type[:integer] || []).map{ |attr|
        ["#{attr.name}_from", "#{attr.name}_to"]
      }.flatten,
    boolean:
      (attrs_with_type[:boolean] || []).flatten.map(&:name)
  }
end

@design = multiple_choice("Please Choise use design frame work", [:bootstrap, :material])


### Gem ###

append_file 'Gemfile', <<-GEMFILE
# コンソールをまともにする
gem 'pry-rails'
gem 'pry-doc'

# platform windows only?
gem 'rb-readline', require: false

# ログフォーマッター
gem 'log4r'

## DB
# created_by, updated_by, deleted_byを自動挿入
gem 'record_with_operator'
# セッションをDBに格納
gem 'activerecord-session_store'
# 現在のDBをseedに吐き出す
gem 'seed_dump'

## helper
# viewのフォームをシンプルに
gem 'simple_form'
# ページネート
gem 'kaminari'
# enumのヘルパーを提供
gem 'enum_help'

## assets
# JSライブラリ達
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem "select2-rails"
gem 'momentjs-rails'
gem 'bootstrap-datepicker-rails', '1.1.1.11'
# bootstrap
gem 'bootstrap-sass'

group :development, :test do
  # コンソールでActiveRecordオブジェクトを整形
  # gem 'hirb'
  # gem 'hirb-unicode'
  # エラー画面をわかりやすく
  gem 'better_errors'
  # エラー場面でデバッグ
  gem 'binding_of_caller', platform: :ruby
  # i18nを自動生成
  gem 'i18n_generators'
  # schemeをWebで確認
  gem 'ryakuzu'
  # N+1を検知
  gem 'bullet'
  # schemeをmodelに書き出す
  gem 'annotate'
  # gemのライセンスをチェック
  gem 'license_finder'
  # コーディング規約
  gem 'rubocop'
  # セキュリティチェック
  gem 'brakeman'
  # gemの脆弱性チェック
  gem 'bundler-audit'
  # フォーマッター
  gem 'rufo'
  # ER図自動生成
  gem 'rails-erd'
end
GEMFILE

gsub_file "Gemfile", "# gem 'therubyracer'", "gem 'therubyracer'"


### Application Settings ###

copy_file "./lib/custom_logger.rb"
copy_file "./lib/log4r.rb"

add_require = <<ADD_REQUIRE

require File.expand_path("../../lib/log4r.rb", __FILE__)
include Log4r
ADD_REQUIRE

append_file 'config/application.rb', add_require, after: "Bundler.require(*Rails.groups)\n"

application <<'APP'
config.active_record.default_timezone = :local
    config.time_zone = 'Tokyo'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    I18n.enforce_available_locales = false

    config.colorize_logging = false
    require File.dirname(__FILE__) + "/../lib/custom_logger"
    config.logger = CustomLogger::SystemLogger.instance.logger
    Log4r::Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer

    config.autoload_paths += %W(#{config.root}/lib)

    config.generators do |g|
      g.helper false
      g.assets false
      g.test_framework false
    end
    config.generators.template_engine = :erb
    # Don't generate system test files.
    config.generators.system_tests = nil
APP

append_file "config/database.yml", " admin", after: "password:"
gsub_file "config/database.yml", "localhost", "127.0.0.1"
gsub_file "config/database.yml", "_production", ""


after_bundle do
  ### Make Files ###

  run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss'

  run "wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/"

  rake "app:templates:copy"
  generate "simple_form:install --bootstrap -f"
  generate 'kaminari:config'
  generate 'kaminari:views bootstrap3'

  generate "active_record:session_migration"
  session_migration_file = Dir.glob("db/migrate/*_add_sessions_table.rb").first
  gsub_file session_migration_file, "ActiveRecord::Migration\n", "ActiveRecord::Migration[5.1]\n"

  copy_file "./config/initializers/simple_form.rb", force: true
  copy_file "./config/initializers/simple_form_#{@design.to_s.downcase}.rb", force: true

  copy_file "./config/locales/kaminari.ja.yml"
  copy_file "./config/locales/simple_form.ja.yml"


  ### Assets ###

  case @design
  when :bootstrap
    gsub_file "app/assets/javascripts/application.js", "//= require_tree .", <<JS
// require_tree .
//= require jquery
// require jquery_nested_form
//= require select2
//= require select2_locale_ja
// require jquery.remotipart
// require jquery.iframe-transport.js
//= require bootstrap-sprockets
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.ja
// require bootstrap-timepicker

$(document).on('turbolinks:load', function () {
  $('.select2').select2({
//    theme: "bootstrap"
  });
  $('input.datepicker').datepicker({
    format: 'yyyy/mm/dd',
    language: 'ja',
    autoclose: true
  });
  $('span.for-datepicker').on('click', function() {
    $(this).prev().focus();
  });
});
JS

    gsub_file "app/assets/stylesheets/application.scss", " *= require_tree .", " * require_tree ."

    append_file "app/assets/stylesheets/application.scss", <<CSS, after: "require_self\n"
 *= require select2
 *= require select2-bootstrap
 *= require bootstrap-datepicker
 * require bootstrap-timepicker
CSS

    append_file "app/assets/stylesheets/application.scss", <<CSS

@import "_custom_variables.scss";
@import "bootstrap-sprockets";
@import "bootstrap";
/*@import 'bootstrap-timepicker';*/

@font-face{
  font-family: 'Glyphicons Halflings';
  src: image-url("bootstrap/glyphicons-halflings-regular.eot");
  src: image-url("bootstrap/glyphicons-halflings-regular.eot?#iefix") format("embedded-opentype"),
       image-url("bootstrap/glyphicons-halflings-regular.woff") format("woff"),
       image-url("bootstrap/glyphicons-halflings-regular.ttf") format("truetype"),
       image-url("bootstrap/glyphicons-halflings-regular.svg#glyphicons_halflingsregular") format("svg")
}

body { padding-top: 50px; padding-bottom: 50px; }
footer.navbar { min-height: 30px; }
abbr { color: $brand-danger; }

/* For Datepicker */
.form-actions { text-align: center; }
div.datepicker-days > table.table-condensed > thead > tr > th.dow:first-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:first-child {
  /*background-color: lighten($brand-danger, 33.3%);*/
  color: $brand-danger;
}
div.datepicker-days > table.table-condensed > thead > tr > th.dow:last-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:last-child {
  /*background-color: lighten($brand-primary, 33.3%);*/
  color: $brand-primary;
}
CSS

    create_file "app/assets/stylesheets/_custom_variables.scss", "/* Go to http://www.lavishbootstrap.com */"

  when :material
    directory "app/assets/stylesheets/material"
    directory "app/assets/javascripts/material"

    gsub_file "app/assets/javascripts/application.js", "//= require_tree .", <<JS
// require_tree .
//= require jquery
// require jquery_nested_form
//= require material/material
//= require material/ripples
//= require select2
//= require select2_locale_ja
// require jquery.remotipart
// require jquery.iframe-transport.js
//= require bootstrap-sprockets
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.ja
// require bootstrap-timepicker

$(document).on('turbolinks:load', function () {
  // material design initialize
  $('.select2').parents('.form-group').removeClass('label-floating');
  $.material.init();
  $('.select2').select2({
//    theme: "bootstrap"
  });
  $('input.datepicker').datepicker({
    format: 'yyyy/mm/dd',
    language: 'ja',
    autoclose: true
  });
  $('span.for-datepicker').on('click', function() {
    $(this).prev().focus();
  });
});
JS

    gsub_file "app/assets/stylesheets/application.scss", " *= require_tree .", " * require_tree ."

    append_file "app/assets/stylesheets/application.scss", <<CSS, after: "require_self\n"
 *= require material/bootstrap-material-design
 *= require material/ripples
 *= require select2
 *= require select2-bootstrap
 *= require bootstrap-datepicker
 * require bootstrap-timepicker
CSS
    append_file "app/assets/stylesheets/application.scss", <<CSS

@import "bootstrap-sprockets";
@import "bootstrap";
/*@import 'bootstrap-timepicker';*/

@font-face{
  font-family: 'Glyphicons Halflings';
  src: image-url("bootstrap/glyphicons-halflings-regular.eot");
  src: image-url("bootstrap/glyphicons-halflings-regular.eot?#iefix") format("embedded-opentype"),
       image-url("bootstrap/glyphicons-halflings-regular.woff") format("woff"),
       image-url("bootstrap/glyphicons-halflings-regular.ttf") format("truetype"),
       image-url("bootstrap/glyphicons-halflings-regular.svg#glyphicons_halflingsregular") format("svg")
}

body { padding-top: 50px; padding-bottom: 50px; }
footer.navbar { min-height: 30px; }
abbr { color: $brand-danger; }
.form-actions { text-align: center; }
.form-group.select { margin-top: 0; }

/* For Datepicker */
.form-actions { text-align: center; }
div.datepicker-days > table.table-condensed > thead > tr > th.dow:first-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:first-child {
  /*background-color: lighten($brand-danger, 33.3%);*/
  color: $brand-danger;
}
div.datepicker-days > table.table-condensed > thead > tr > th.dow:last-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:last-child {
  /*background-color: lighten($brand-primary, 33.3%);*/
  color: $brand-primary;
}
CSS

  end


  ### Models ###

  append_file "app/models/application_record.rb", <<'ACTIVERECORD', after: "self.abstract_class = true\n"

#  include CustomValidaters

  scope :deleted, -> { where.not(deleted_at: nil)}
  scope :active, -> { where(deleted_at: nil)}
  scope :column_symbols, -> { column_names.map(&:to_sym) }
#  records_with_operator_on :create, :update, :destroy
#  belongs_to :creater, class_name: "MUser", foreign_key: :created_by
#  belongs_to :updater, class_name: "MUser", foreign_key: :updated_by
#  before_save -> { self.deleted_by = nil if self.deleted_at.blank? }

  # 論理削除
  def logical_delete!
    self.deleted_at = Time.zone.now
#    self.deleted_by = operator.try(:id)
    self.save!(validate: false)
  end

  def deleted?
    self.deleted_at.present?
  end

  def active?
    self.deleted_at.blank?
  end

  def to_s
    "#{self.try(:name) || self.id}"
  end
ACTIVERECORD

  copy_file "./lib/active_model_base.rb"


  ### Views ###

  create_file "app/views/layouts/application.html.erb", <<LAYOUT, force: true
<!DOCTYPE html>
<html lang="ja">
<head>
<title>#{@app_name.camelize}</title>
<%= csrf_meta_tags %>

<%= stylesheet_link_tag 'application', media: 'all', :'data-turbolinks-track' => 'reload' %>
<%= javascript_include_tag 'application', :'data-turbolinks-track' => 'reload' %>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<%= csrf_meta_tags %>
<%#= favicon_link_tag '/images/icon-144.png', :rel => 'apple-touch-icon', :type => 'image/png', :sizes => '144x144' %>
<%#= favicon_link_tag '/images/icon-114.png', :rel => 'apple-touch-icon', :type => 'image/png', :sizes => '114x114' %>
<%#= favicon_link_tag '/images/icon-72.png', :rel => 'apple-touch-icon', :type => 'image/png', :sizes => '72x72' %>
<%#= favicon_link_tag '/images/icon.png', :rel => 'apple-touch-icon', :type => 'image/png' %>
<%#= favicon_link_tag '/images/favicon.ico', :rel => 'shortcut icon' %>
</head>
<body>

<nav class="navbar navbar-fixed-top navbar-inverse">
<div class="container">
<!-- Brand and toggle get grouped for better mobile display -->
<div class="navbar-header">
<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
<span class="sr-only">Toggle navigation</span>
<span class="icon-bar"></span>
<span class="icon-bar"></span>
<span class="icon-bar"></span>
</button>
<a class="navbar-brand" href="#">#{@app_name.camelize}</a>
<%#= link_to "#{@app_name.camelize}", route_path, class: "navbar-brand" %>
</div>

<!-- Collect the nav links, forms, and other content for toggling -->
<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
<ul class="nav navbar-nav">
<li class="active"><a href="#">Link <span class="sr-only">(current)</span></a></li>
<li><a href="#">Link</a></li>
<li class="dropdown">
<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Dropdown <span class="caret"></span></a>
<ul class="dropdown-menu">
<li><a href="#">Action</a></li>
<li><a href="#">Another action</a></li>
<li><a href="#">Something else here</a></li>
<li role="separator" class="divider"></li>
<li><a href="#">Separated link</a></li>
<li role="separator" class="divider"></li>
<li><a href="#">One more separated link</a></li>
</ul>
</li>
</ul>
<form class="navbar-form navbar-left">
<div class="form-group">
<input class="form-control col-md-8" placeholder="Search" type="text">
</div>
</form>
<ul class="nav navbar-nav navbar-right">
<li><a href="#">Link</a></li>
<li class="dropdown">
<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Dropdown <span class="caret"></span></a>
<ul class="dropdown-menu">
<li><a href="#">Action</a></li>
<li><a href="#">Another action</a></li>
<li><a href="#">Something else here</a></li>
<li role="separator" class="divider"></li>
<li><a href="#">Separated link</a></li>
</ul>
</li>
</ul>
</div><!-- /.navbar-collapse -->
</div><!-- /.container -->
</nav>

<div class="container">
<%= content_tag :h2, (@page_name || [controller_name.titleize, action_name].join(":")) %>

<%- flash.each do |name, msg| -%>
<div class="alert alert-<%= name == "notice" ? "success" : "danger" %>">
<button type="button" class="close" data-dismiss="alert">×</button>
<%= msg %>
</div>
<%- end -%>

<%= yield %>

<footer class="navbar navbar-inverse navbar-fixed-bottom">
<div class="container">
<p class="text-right"> Copyright &copy; swan_match</p>
</div>
</footer>

</div><!-- /container -->

</body>
</html>
LAYOUT

  ### Scaffold Templates ###

  directory "lib/templates/erb/scaffold", force: true
  append_file "lib/templates/erb/scaffold/_form.html.erb", ', html: { class: "form-horizontal" }', after: "url: url" if @design == :bootstrap
  append_file "lib/templates/erb/scaffold/index.html.erb", ', html: { class: "form-horizontal" }', after: "method: :get" if @design == :bootstrap
  directory "lib/templates/migration", force: true
  directory "lib/templates/active_record", force: true
  directory "app/inputs", force: true
  if @design == :bootstrap
    gsub_file "app/inputs/custom_date_input.rb", "btn", "addon"
    gsub_file "app/inputs/date_range_input.rb", "btn", "addon"
    gsub_file "app/inputs/int_range_input.rb", "btn", "addon"
  end
  gsub_file "lib/templates/rails/scaffold_controller/controller.rb", "@<%= plural_table_name %> = <%= orm_class.all(class_name) %>\n", <<INDEX
@search_<%= singular_table_name %> = <%= class_name %>::Search.new(search_params)
    @<%= plural_table_name %> = @search_<%= singular_table_name %>.search(params[:page])
INDEX
  gsub_file "lib/templates/rails/scaffold_controller/controller.rb", '<%= orm_class.find(class_name, "params[:id]") %>', '<%= class_name %>.active.find(params[:id])'
  gsub_file "lib/templates/rails/scaffold_controller/controller.rb", '<%= orm_instance.destroy %>', '<%= singular_table_name %>.logical_delete!'
  prepend_file "lib/templates/rails/scaffold_controller/controller.rb", "# coding: utf-8\n"
  append_file "lib/templates/rails/scaffold_controller/controller.rb", <<BEFORE_ACTIONS, after: "ApplicationController\n"
<%- attributes.select(&:reference?).each do |attribute| -%>
  before_action :set_<%= attribute.name %>_options, only: [:index, :show, :edit, :new]
<%- end -%>
BEFORE_ACTIONS
  append_file "lib/templates/rails/scaffold_controller/controller.rb", <<'OPTIONS', after: "private\n"
    # Search params
    def search_params
      if params[:<%= singular_table_name %>_search]
        <%- if attributes_names.empty? -%>
        params.fetch(:<%= singular_table_name %>_search, {})
        <%- else -%>
<%-
attrs_with_type = attributes.group_by(&:type)
search_attrs = {
  text: [
      attrs_with_type[:string],
      attrs_with_type[:text]
    ].flatten.compact.map(&:name),
  date:
    (attrs_with_type[:date] || []).map { |attr|
      ["#{attr.name}_from", "#{attr.name}_to"]
    }.flatten,
  datetime: [
      attrs_with_type[:datetime],
      attrs_with_type[:timestamp],
      attrs_with_type[:time]
    ].flatten.compact.map{ |attr|
      ["#{attr.name}_from", "#{attr.name}_to"]
    }.flatten,
  integer: [
      attrs_with_type[:integer],
      attrs_with_type[:float],
      attrs_with_type[:decimal]
    ].flatten.compact.map{ |attr|
      ["#{attr.name}_from", "#{attr.name}_to"]
    }.flatten,
  boolean:
    (attrs_with_type[:boolean] || []).flatten.map(&:name),
  references:
    (attrs_with_type[:references] || []).flatten.map do |attr|
      "#{attr.name} => []"
    end
}
-%>
        params.require(:<%= singular_table_name %>_search).permit(:<%= search_attrs.values.flatten.compact.join(', :') %>)
      <%- end -%>
      else
        {}
      end
    end

<%- attributes.select(&:reference?).each do |attribute| -%>
    # Set <%= attribute.name %> select tag options.
    def set_<%= attribute.name %>_options
      @<%= attribute.name %>_options = <%= attribute.name.classify %>.active.map{ |<%= attribute.name %>| [<%= attribute.name %>.to_s, <%= attribute.name %>.id] }
    end

<%- end -%>
OPTIONS

  case @design
  when :bootstrap
    append_file "lib/templates/erb/scaffold/_form.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each do |attribute| -%>
      <div class="row">
        <div class="col-md-12">
  <%- if attribute.reference? -%>
          <%%= f.association(
            :<%= attribute.name %>,
            include_blank: "(未選択)",
            collection: @<%= attribute.name %>_options,
            input_html: {
	            class: "select2"
	          },
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            },
              disabled: only_show
            )
          %>
  <%- else -%>
          <%%= f.input(
            :<%= attribute.name %>,
    <%- if attribute.type == :date -%>
            as: :custom_date,
    <%- end -%>
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            },
              disabled: only_show
            )
          %>
  <%- end -%>
        </div>
      </div>
<%- end -%>
INPUTS
    append_file "lib/templates/erb/scaffold/index.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each do |attribute| -%>
      <div class="row">
        <div class="col-md-12">
  <%- if attribute.reference? -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :select,
            collection: @<%= attribute.name %>_options,
            input_html: {
	            class: "select2",
              multiple: true
	          },
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            }
          ) %>
  <%- elsif [:integer, :float, :decimal].include? attribute.type -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :int_range,
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            }
          ) %>
  <%- elsif [:date, :time, :datetime, :timestamp].include? attribute.type -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :date_range,
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            }
          ) %>
  <%- else -%>
          <%%= f.input(
            :<%= attribute.name %>,
            label_html: {
              class: "col-md-3"
            },
            input_wrapper_html: {
              class: "col-md-9"
            }
          ) %>
  <%- end -%>
        </div>
      </div>
<%- end -%>
INPUTS
  when :material
    append_file "lib/templates/erb/scaffold/_form.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each_slice(2) do |pair| -%>
      <div class="row">
  <%- pair.each do |attribute| -%>
    <%- if pair -%>
        <div class="col-md-6">
      <%- if attribute.reference? -%>
          <%%= f.association(
            :<%= attribute.name %>,
            include_blank: "(未選択)",
            collection: @<%= attribute.name %>_options,
            input_html: {
              class: "select2"
            },
            disabled: only_show
          ) %>
      <%- else -%>
          <%%= f.input(
            :<%= attribute.name %>,
        <%- if attribute.type == :date -%>
            as: :custom_date,
        <%- end -%>
            disabled: only_show
          ) %>
      <%- end -%>
        </div>
    <%- end -%>
  <%- end -%>
      </div>
<%- end -%>
INPUTS
    append_file "lib/templates/erb/scaffold/index.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each_slice(2) do |pair| -%>
      <div class="row">
  <%- pair.each do |attribute| -%>
    <%- if pair -%>
        <div class="col-md-6">
      <%- if attribute.reference? -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :select,
            collection: @<%= attribute.name %>_options,
            input_html: {
              class: "select2",
              multiple: true
            }
          ) %>
  <%- elsif [:integer, :float, :decimal].include? attribute.type -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :int_range
          ) %>
  <%- elsif [:date, :time, :datetime, :timestamp].include? attribute.type -%>
          <%%= f.input(
            :<%= attribute.name %>,
            as: :date_range
          ) %>
      <%- else -%>
          <%%= f.input(
            :<%= attribute.name %>,
        <%- if attribute.type == :date -%>
            as: :custom_date,
        <%- end -%>
          ) %>
      <%- end -%>
        </div>
    <%- end -%>
  <%- end -%>
      </div>
<%- end -%>
INPUTS
  end


  ### Rakefile ###

  append_file "Rakefile", <<RAKE
desc 'Migration After task'
task :after do
  puts 'generate i18n'
  puts `bundle exec rails g i18n_translation ja -f`
  puts 'generate annotate'
  puts `bundle exec annotate`
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['after'].invoke
  puts 'generate erd'
  Rake::Task['erd'].invoke
end
RAKE


  ### Run Initial Commands ###

  rake "db:create"

  git :init
  git add: "."
  git commit: "-am 'Initial commit.'"


  ### Finish Message ###

  puts <<MESSAGE

   ###################################################################
  ##                                                                 ##
  ##  Please enjoy your trip of the Limited Express Train on Rails!  ##
  ##                                                                 ##
   ###################################################################
      _Ｏ
  〈_〉
  ＿
 ||ｎｎ ─┐  y──────────、,──────────、_______
(￣￣￣|囗|   |日　口口口口口口口口| |口口口口口口口口口口| |ロ ロ|
[三三五Ｌ_」__|＿＿＿＿＿＿＿＿＿＿|_|＿＿＿＿＿＿＿＿＿＿|_|_____凵
∠7◎◎◎=◎~~~  ◎=◎        ◎=◎  ~  ◎=◎         ◎=◎ ~ ◎=◎
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=
MESSAGE
end
