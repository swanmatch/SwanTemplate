# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class IntRangeInput < SimpleForm::Inputs::Base
  def input
    template.content_tag(:div, class: "input-group") do
      input_html_options[:class] << ['form-control']
      template.concat @builder.text_field("#{attribute_name}_from", input_html_options)
      template.concat range_icon
      template.concat @builder.text_field("#{attribute_name}_to", input_html_options)
    end
  end

  def range_icon
    template.content_tag(:span, class: 'input-group-btn btn') do
      template.concat '<span class="add-on glyphicon glyphicon-option-horizontal"></span>'.html_safe
    end
  end

end