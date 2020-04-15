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

@design = multiple_choice("Please Choise use design frame work", [:bootstrap, :material])

def bootstrap?
  @design == :bootstrap
end
def material?
  @design == :material
end

### Gem ###

append_file './Gemfile', <<GEMFILE
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
gem 'bootstrap-datepicker-rails'
# bootstrap
gem 'bootstrap', '~> 4.3.1'
#{"gem 'material-sass', '4.1.1'" if material? }
gem 'material_icons'

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

gsub_file "./Gemfile", "# gem 'therubyracer'", "gem 'therubyracer'"


### Application Settings ###

create_file "./config/initializers/session_store.rb", "Rails.application.config.session_store :active_record_store, key: '_#{@app_name}_session'"

application <<'APP'
    config.active_record.default_timezone = :local
    config.time_zone = 'Tokyo'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    I18n.enforce_available_locales = false

    config.colorize_logging = false

    config.enable_dependency_loading = true
    config.autoload_paths += %W(#{config.root}/lib)
#    config.paths.add 'lib/.', eager_load: true

    config.generators do |g|
      g.assets false
      g.test_framework false
      g.helper false
      g.system_tests = nil
      g.template_engine :erb
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil
APP

append_file "./config/database.yml", " admin", after: "password:"
gsub_file "./config/database.yml", "localhost", "127.0.0.1"
gsub_file "./config/database.yml", "_production", ""


after_bundle do
  ### Make Files ###

  copy_file './app/assets/stylesheets/application.css', './app/assets/stylesheets/application.scss'
  remove_file './app/assets/stylesheets/application.css'

  get "https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml", "./config/locales/ja.yml"

  rake "app:templates:copy"
  generate "simple_form:install --bootstrap -f"
  generate 'kaminari:config'
  generate 'kaminari:views bootstrap4'
  generate 'erd:install'
  generate 'annotate:install'

  generate "generator swaffold"
  prepend_file "./lib/generators/swaffold/swaffold_generator.rb", "require 'rails/generators/rails/scaffold/scaffold_generator'\n"
  gsub_file "./lib/generators/swaffold/swaffold_generator.rb", "NamedBase", "ScaffoldGenerator"
  gsub_file "./lib/generators/swaffold/swaffold_generator.rb", "source_root File.expand_path('templates', __dir__)", <<'HOOK'
def main
    insert_into_file "app/views/layouts/application.html.erb", "<li class=\"nav-item\"><%= link_to #{class_name.singularize}.model_name.human, #{plural_table_name}_path, class: 'nav-link' %></li>\n", after: "<ul class=\"navbar-nav mr-auto\">\n"
  end
#  hook_for :scaffold
HOOK

  generate "active_record:session_migration"
  session_migration_file = Dir.glob("db/migrate/*_add_sessions_table.rb").first
  gsub_file session_migration_file, "ActiveRecord::Migration\n", "ActiveRecord::Migration[5.1]\n"

  copy_file "./config/locales/kaminari.ja.yml"
  copy_file "./config/locales/simple_form.ja.yml"

  gsub_file "./config/initializers/simple_form_bootstrap.rb", ", class: 'col-sm-9'", "", force: true
  gsub_file "./config/initializers/simple_form_bootstrap.rb", "col-sm-3 ",  "", force: true
  gsub_file "./config/initializers/simple_form_bootstrap.rb", ":grid_wrapper", ":input_wrapper", force: true
if bootstrap?
    gsub_file "./config/initializers/simple_form_bootstrap.rb", "config.default_wrapper = :vertical_form", "config.default_wrapper = :horizontal_form", force: true
    gsub_file "./config/initializers/simple_form_bootstrap.rb", /config.wrapper_mappings.*}/m, <<MAPPING
config.wrapper_mappings = {
               boolean: :horizontal_boolean,
           check_boxes: :horizontal_collection_inline,
                  date: :horizontal_multi_select,
              datetime: :horizontal_multi_select,
                  file: :horizontal_file,
         radio_buttons: :horizontal_collection_inline,
    enum_radio_buttons: :horizontal_collection_inline,
                 range: :horizontal_range,
                  time: :horizontal_multi_select
  }
MAPPING
  else # material?
    gsub_file "./config/initializers/simple_form_bootstrap.rb", "config.default_wrapper = :vertical_form", "config.default_wrapper = :floating_labels_form", force: true
    gsub_file "./config/initializers/simple_form_bootstrap.rb", /config.wrapper_mappings.*}/m, <<MAPPING
config.wrapper_mappings = {
               boolean: :vertical_boolean,
           check_boxes: :vertical_collection_inline,
                  date: :vertical_multi_select,
              datetime: :vertical_multi_select,
                  file: :vertical_file,
         radio_buttons: :vertical_collection_inline,
    enum_radio_buttons: :vertical_collection_inline,
                 range: :vertical_range,
                  time: :vertical_multi_select
  }
MAPPING
  end

  ### Assets ###

  case @design
  when :bootstrap
    gsub_file "./app/assets/javascript/packs/application.js", "//= require_tree .", <<JS
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

$(document).on("turbolinks:before-cache", function() {
    $('.select2-input').select2('destroy');
});
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

    gsub_file "./app/assets/stylesheets/application.scss", " *= require_tree .", " * require_tree ."

    append_file "./app/assets/stylesheets/application.scss", <<CSS, after: "require_self\n"
 *= require select2
 *= require select2-bootstrap
 *= require bootstrap-datepicker
 *= require material_icons
 * require bootstrap-timepicker
CSS

    append_file "./app/assets/stylesheets/application.scss", <<CSS

@import "_custom_variables";
@import "bootstrap";
/*@import 'bootstrap-timepicker';*/

body { margin-top: 60px; margin-bottom: 30px; }
abbr { color: $danger; }

/* For Datepicker */
.form-actions { text-align: center; }
div.datepicker-days > table.table-condensed > thead > tr > th.dow:first-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:first-child {
  /*background-color: lighten($danger, 33.3%);*/
  color: $danger;
}
div.datepicker-days > table.table-condensed > thead > tr > th.dow:last-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:last-child {
  /*background-color: lighten($primary, 33.3%);*/
  color: $primary;
}
CSS

    create_file "./app/assets/stylesheets/_custom_variables.scss", "/* Go to http://www.lavishbootstrap.com */"

  when :material
    gsub_file "./app/javascript/packs/application.js", "//= require_tree .", <<JS
// require_tree .
//= require jquery
// require jquery_nested_form
//= require select2
//= require select2_locale_ja
// require jquery.remotipart
// require jquery.iframe-transport.js
//= require popper
//= require bootstrap
//= require material
// require bootstrap-datepicker/core
// require bootstrap-datepicker/locales/bootstrap-datepicker.ja
// require bootstrap-timepicker

$(document).on("turbolinks:before-cache", function() {
    $('.select2-input').select2('destroy');
});
$(document).on('turbolinks:load', function () {
  $('.select2').parents('.form-group').removeClass('label-floating');
  $('.select2').select2({
//    theme: "bootstrap"
  });
  $('input.datepicker').pickdate({
    format: 'yyyy/mm/dd',
    labelMonthNext: '翌月',
    labelMonthPrev: '先月',
    labelMonthSelect: '月',
    labelYearSelect: '年',
    monthsLong: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
    monthsShort: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
    weekdaysFull: ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'],
    weekdaysShort: ['日', '月', '火', '水', '木', '金', '土'],
  });
  $('span.for-datepicker').on('click', function() {
    $(this).prev().focus();
  });
});
JS

    gsub_file "./app/assets/stylesheets/application.scss", " *= require_tree .", " * require_tree ."

    append_file "./app/assets/stylesheets/application.scss", <<CSS, after: "require_self\n"
 *= require select2
 *= require select2-bootstrap
 *= require material_icons
 * require bootstrap-datepicker
 * require bootstrap-timepicker
CSS
    append_file "./app/assets/stylesheets/application.scss", <<CSS

@import "material";
/*@import 'bootstrap-timepicker';*/

body { margin-top: 60px; margin-bottom: 30px; }
abbr { color: theme-color("danger"); }
.form-actions { text-align: center; }
.form-group.select { margin-top: 0; }

/* For Datepicker */
.form-actions { text-align: center; }
div.datepicker-days > table.table-condensed > thead > tr > th.dow:first-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:first-child {
  /*background-color: lighten($danger, 33.3%);*/
  color: theme-color("danger");
}
div.datepicker-days > table.table-condensed > thead > tr > th.dow:last-child,
div.datepicker-days > table.table-condensed > tbody > tr > td.day:last-child {
  /*background-color: lighten($primary, 33.3%);*/
  color: theme-color("info");
}
CSS

  end


  ### Models ###

  append_file "./app/models/application_record.rb", <<ACTIVERECORD, after: "self.abstract_class = true\n"

  include CustomValidators

  scope :deleted, -> { where.not(deleted_at: nil)}
  scope :active, -> { where(deleted_at: nil)}
  scope :column_symbols, -> { column_names.map(&:to_sym) }
  scope :like, ->(column, word) { where("`\#{table_name}`.`\#{column}` LIKE ?", "%\#{word}%") }
  scope :less, ->(column, value) { where("`\#{table_name}`.`\#{column}` <= ?", value) }
  scope :more, ->(column, value) { where("`\#{table_name}`.`\#{column}` >= ?", value) }
#  records_with_operator_on :create, :update, :destroy

  # 論理削除
  def logical_delete!
    self.deleted_at = Time.zone.now
    self.deleted_by = operator.try(:id)
    self.save!(validate: false)
  end

  def deleted?
    self.deleted_at.present?
  end

  def active?
    self.deleted_at.blank?
  end

  def self.between(column, from, to)
    if from.present? && to.present?
      self.where(column => from..to)
    elsif from.present?
      self.more(column, from)
    elsif to.present?
      self.less(column, to)
    else
      all
    end
  end
ACTIVERECORD
  copy_file "./app/models/concerns/active_model_base.rb"
  copy_file "./app/models/concerns/custom_validators.rb"
  copy_file "./app/models/session.rb"


  ### Views ###

  copy_file "./app/views/layouts/application_bs4.html.erb", "./app/views/layouts/application.html.erb", force: true
  gsub_file "./app/views/layouts/application.html.erb", "APPNAME", @app_name.camelize

  ### Scaffold Templates ###

  directory "./lib/templates/erb/scaffold", force: true
  append_file "./lib/templates/erb/scaffold/_form.html.erb", ', html: { class: "form-horizontal" }', after: "url: url" if @design == :bootstrap
  append_file "./lib/templates/erb/scaffold/index.html.erb", ', html: { class: "form-horizontal" }', after: "method: :get" if @design == :bootstrap
  directory "./lib/templates/migration", force: true
  directory "./lib/templates/active_record", force: true
  directory "./app/inputs", force: true
  if @design == :bootstrap
    gsub_file "./app/inputs/custom_date_input.rb", "btn", "addon"
    gsub_file "./app/inputs/date_range_input.rb", "btn", "addon"
    gsub_file "./app/inputs/int_range_input.rb", "btn", "addon"
  end
  gsub_file "lib/templates/rails/scaffold_controller/controller.rb.tt", "@<%= plural_table_name %> = <%= orm_class.all(class_name) %>\n", <<INDEX
@search_<%= singular_table_name %> = <%= class_name %>::Search.new(search_params)
    @<%= plural_table_name %> = @search_<%= singular_table_name %>.search(params[:page])
INDEX
  gsub_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", '<%= orm_class.find(class_name, "params[:id]") %>', '<%= class_name %>.active.find(params[:id])'
  gsub_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", '<%= orm_instance.destroy %>', '<%= singular_table_name %>.logical_delete!'
  gsub_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", "permit(<%= attributes_names.map { |name| \":\#{name}\" }.join(', ') %>)", "permit(<%= attributes_names.map { |name| \":\#{name}\" }.join(', ') %>, :lock_version)"

  prepend_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", "# coding: utf-8\n"
  append_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", <<BEFORE_ACTIONS, after: "ApplicationController\n"
<%- attributes.select(&:reference?).each do |attribute| -%>
  before_action :set_<%= attribute.name %>_options, only: [:index, :show, :edit, :new, :update, :create]
<%- end -%>
BEFORE_ACTIONS
  append_file "./lib/templates/rails/scaffold_controller/controller.rb.tt", <<'OPTIONS', after: "private\n"
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
    append_file "./lib/templates/erb/scaffold/_form.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each do |attribute| -%>
      <div class="row">
        <div class="col-md">
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
          ) %>
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
          ) %>
  <%- end -%>
        </div>
      </div>
<%- end -%>
INPUTS
    append_file "./lib/templates/erb/scaffold/index.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each do |attribute| -%>
      <div class="row">
        <div class="col-md">
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
    append_file "./lib/templates/erb/scaffold/_form.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each_slice(2) do |pair| -%>
      <div class="row">
  <%- pair.each do |attribute| -%>
    <%- if pair -%>
        <div class="col-md">
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
    append_file "./lib/templates/erb/scaffold/index.html.erb", <<INPUTS, after: "<div class=\"form-inputs\">\n"
<%- attributes.each_slice(2) do |pair| -%>
      <div class="row">
  <%- pair.each do |attribute| -%>
    <%- if pair -%>
        <div class="col-md">
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

  append_file "./Rakefile", <<RAKE
desc 'Migration After task'
task :i18n do
  puts 'generate i18n'
  puts `bundle exec rails g i18n_translation ja -f`
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['i18n'].invoke
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
