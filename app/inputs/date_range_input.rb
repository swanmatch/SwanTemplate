# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class DateRangeInput < SimpleForm::Inputs::Base
  def input
    template.content_tag(:div, class: "input-group input-group-datepicker") do
      input_html_options[:class] << ['form-control', 'datepicker']
      template.concat @builder.text_field("#{attribute_name}_from", input_html_options)
      template.concat calender_icon
      template.concat range_icon
      template.concat @builder.text_field("#{attribute_name}_from", input_html_options)
      template.concat calender_icon
    end
  end

  def calender_icon
    template.content_tag(:span, class: 'input-group-btn btn for-datepicker') do
      template.concat '<span class="add-on glyphicon glyphicon-calendar"></span>'.html_safe
    end
  end

  def range_icon
    template.content_tag(:span, class: 'input-group-btn btn') do
      template.concat '<span class="add-on glyphicon glyphicon-option-horizontal"></span>'.html_safe
    end
  end

end
