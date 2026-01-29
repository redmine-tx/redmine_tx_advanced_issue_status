class TxAdvancedIssueStatusHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
    if context[:request].params[:controller] == 'issue_statuses' then
      if context[:request].params[:action] == 'index' then
        o = <<EOS
        <script>
          var stage_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status|  issue_status.stage ? l(TxAdvancedIssueStatusHelper::STAGE_OPTIONS[issue_status.stage]) : '' }.to_json };
          var is_paused_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status| issue_status.is_paused? }.to_json };
          $(function() {
            var $stageHeader = $('<th>').text('#{l(:field_stage)}');
            var $pausedHeader = $('<th>').text('#{l(:field_is_paused)}');
            $('.issue_statuses tr').slice(0).find('th:eq(0)').after($pausedHeader).after($stageHeader);
            $('.issue_statuses tbody tr').slice(0).find('td:eq(0)').each(function(index, element) {
              var $stageCell = $('<td>').text(stage_values[index]);
              var $pausedCell = $('<td>').html(is_paused_values[index] ? '&#10003;' : '');
              $(element).after($pausedCell).after($stageCell);
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

            var $stageLabel = $('<label>')
              .attr('for', 'issue_status_stage')
              .text('#{l(:field_stage)}');

            var $stageP = $('<p>').append($stageLabel, $select);

            var $checkbox = $('<input>')
              .attr('type', 'checkbox')
              .attr('name', 'issue_status[is_paused]')
              .attr('id', 'issue_status_is_paused')
              .val('1');
            if (#{issue_status.is_paused? ? 'true' : 'false'}) {
              $checkbox.prop('checked', true);
            }

            var $hidden = $('<input>')
              .attr('type', 'hidden')
              .attr('name', 'issue_status[is_paused]')
              .val('0');

            var $pausedLabel = $('<label>')
              .attr('for', 'issue_status_is_paused')
              .text('#{l(:field_is_paused)}');

            var $pausedP = $('<p>').append($pausedLabel, $hidden, $checkbox);

            $('p label[for="issue_status_is_closed"]').parent().before($stageP).before($pausedP);
          });
        </script>
EOS
        o
      end
    end
  end
end 
