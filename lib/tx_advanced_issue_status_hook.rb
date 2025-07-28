class TxAdvancedIssueStatusHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
    if context[:request].params[:controller] == 'issue_statuses' then
      if context[:request].params[:action] == 'index' then
        o = <<EOS
        <script>
          var stage_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status|  issue_status.stage ? l(TxAdvancedIssueStatusHelper::STAGE_OPTIONS[issue_status.stage]) : '' }.to_json };
          $(function() {
            var $header = $('<th>').text('#{l(:field_stage)}');
            $('.issue_statuses tr').slice(0).find('th:eq(0)').after($header);
            $('.issue_statuses tbody tr').slice(0).find('td:eq(0)').each(function(index, element) {
              var $cell = $('<td>').text(stage_values[index]);
              $(element).after($cell);
            });
          });
        </script>
EOS
        o
      elsif ['edit', 'new'].include?(context[:request].params[:action]) then
        issue_status = context[:controller].instance_variable_get(:@issue_status)
        
        o = <<EOS
        <script>
          $(function() {
            var $select = $('<select>').attr('name', 'issue_status[stage]');
            $select.append($('<option>').val('').text(''));
            
            var stageOptions = #{TxAdvancedIssueStatusHelper::STAGE_OPTIONS.map{ |key, value| [key, l(value)] }.to_h.to_json};
            Object.keys(stageOptions).forEach(function(key) {
              var $option = $('<option>')
                .val(key)
                .text(stageOptions[key]);
              if (#{issue_status.stage.to_json} == key) {
                $option.prop('selected', true);
              }
              $select.append($option);
            });

            var $label = $('<label>')
              .attr('for', 'issue_status_stage')
              .text('#{l(:field_stage)}');

            var $p = $('<p>').append($label, $select);
            $('p label[for="issue_status_is_closed"]').parent().before($p);
          });
        </script>
EOS
        o
      end
    end
  end
end 
