# coding: utf-8
<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]
<%- attributes.select(&:reference?).each do |attribute| -%>
  before_action :set_<%= attribute.name %>, only: [:show, :edit, :new]
<%- end -%>

  # GET <%= route_url %>
  def index
    @<%= plural_table_name %> = <%= class_name %>.active.page(params[:page])
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    if @<%= orm_instance.save %>
      redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name}を作成しました。'" %>
    else
      render :new
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name}を更新しました。'" %>
    else
      render :edit
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= plural_table_name %>.logical_delete!
    redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name}を削除しました。'" %>
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

<%- attributes.select(&:reference?).each do |attribute| -%>
    def set_<%= attribute.name %>_options
      @<%= attribute.name %>_options = <%= attribute.name.classify %>.active.map{ |<%= attribute %>| <%= attribute %>.to_s: <%= attribute %>.id }
    end
<%- end -%>

    # Only allow a trusted parameter "white list" through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params.fetch(:<%= singular_table_name %>, {})
      <%- else -%>
      params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
      <%- end -%>
    end
end
<% end -%>
