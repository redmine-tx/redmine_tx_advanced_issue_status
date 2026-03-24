class TxAdvancedIssueStatusHook < Redmine::Hook::ViewListener
  def view_custom_fields_form_issue_custom_field(context)
    custom_field = context[:custom_field]
    form = context[:form]

    content_tag(:p) do
      safe_join(
        [
          form.check_box(:sync_to_children_on_parent_change),
          content_tag(:em, l(:text_sync_to_children_on_parent_change_info), class: 'info')
        ],
        ' '
      )
    end
  end

  def view_layouts_base_html_head(context)
    # 커스텀 연산자 "wk", "im"을 값 불필요 연산자로 등록 (콤보박스 숨김)
    o = <<~JS
      <script>
        (function() {
          var origToggleOperator = window.toggleOperator;
          if (origToggleOperator) {
            window.toggleOperator = function(field) {
              var fieldId = field.replace('.', '_');
              var operator = $("#operators_" + fieldId).val();
              if (operator === "wk" || operator === "im") {
                enableValues(field, []);
              } else {
                origToggleOperator(field);
              }
            };
          }
        })();
      </script>
    JS

    if context[:request].params[:controller] == 'issue_statuses'
      if context[:request].params[:action] == 'index'
        show_default_done_ratio = !Issue.use_status_for_done_ratio?
        o += <<EOS
        <script>
          var stage_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status|  issue_status.stage ? l(TxAdvancedIssueStatusHelper::STAGE_OPTIONS[issue_status.stage]) : '' }.to_json };
          var is_paused_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status| issue_status.is_paused? }.to_json };
          var default_done_ratio_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status| issue_status.default_done_ratio || '' }.to_json };
          var show_default_done_ratio = #{show_default_done_ratio.to_json};
          $(function() {
            setTimeout(function() {
              var $table = $('table.issue_statuses');
              if (!$table.length) return;

              var $nameHeader = $table.find('thead th:first');
              var $closedHeader = $table.find('thead th').filter(function() {
                return $(this).text().trim() === '#{l(:field_is_closed)}';
              }).first();
              var $doneRatioHeader = $table.find('thead th').filter(function() {
                return $(this).text().trim() === '#{l(:field_done_ratio)}';
              }).first();
              if (!$nameHeader.length || !$closedHeader.length) return;

              var shouldInsertDoneRatioColumn = show_default_done_ratio && !$doneRatioHeader.length;

              var $stageHeader = $table.find('thead th.tx-stage-header').first();
              if (!$stageHeader.length) {
                $stageHeader = $('<th>').addClass('tx-stage-header').text('#{l(:field_stage)}');
                $nameHeader.after($stageHeader);
              }

              if (shouldInsertDoneRatioColumn) {
                $doneRatioHeader = $('<th>').addClass('tx-done-ratio-header').text('#{l(:field_done_ratio)}');
                $stageHeader.after($doneRatioHeader);
              }

              var $pausedHeader = $table.find('thead th.tx-paused-header').first();
              if (!$pausedHeader.length) {
                $pausedHeader = $('<th>').addClass('tx-paused-header').text('#{l(:field_is_paused)}');
                $closedHeader.before($pausedHeader);
              }

              $table.find('tbody tr').each(function(index) {
                var $row = $(this);
                var $nameCell = $row.find('td.name').first();
                var $descCell = $row.find('td.description').first();
                if (!$nameCell.length || !$descCell.length) return;

                var $stageCell = $row.find('td.tx-stage-cell').first();
                if (!$stageCell.length) {
                  $stageCell = $('<td>').addClass('tx-stage-cell');
                  $nameCell.after($stageCell);
                }
                $stageCell.text(stage_values[index]);

                if (shouldInsertDoneRatioColumn) {
                  var $doneRatioCell = $row.find('td.tx-done-ratio-cell').first();
                  if (!$doneRatioCell.length) {
                    $doneRatioCell = $('<td>').addClass('tx-done-ratio-cell');
                    $stageCell.after($doneRatioCell);
                  }
                  $doneRatioCell.text(default_done_ratio_values[index]);
                }

                var $pausedCell = $row.find('td.tx-paused-cell').first();
                if (!$pausedCell.length) {
                  $pausedCell = $('<td>').addClass('tx-paused-cell');
                  $descCell.before($pausedCell);
                }
                $pausedCell.html(is_paused_values[index] ? '&#10003;' : '');
              });
            }, 0);
          });
        </script>
EOS
      elsif ['edit', 'new'].include?(context[:request].params[:action])
        issue_status = context[:controller].instance_variable_get(:@issue_status)
        done_ratio_values = (0..100).step(Setting.issue_done_ratio_interval.to_i).to_a
        options_default_done_ratio = done_ratio_values.map do |value|
          selected = issue_status.default_done_ratio == value ? 'selected' : ''
          "<option #{selected} value='#{value}'>#{value}%</option>"
        end.join('')
        str_default_done_ratio = [
          "<p>",
            "<label for='issue_status_default_done_ratio'>#{l(:field_done_ratio)}</label>",
            "<select name='issue_status[default_done_ratio]'>",
              "<option value=''></option>",
              options_default_done_ratio,
            "</select>",
          "</p>"
        ].join('')
        show_default_done_ratio = !Issue.use_status_for_done_ratio?

        o += <<EOS
        <script>
          $(function() {
            setTimeout(function() {
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

              var $stageP = $('p.tx-stage-field').first();
              if (!$stageP.length) {
                var $stageLabel = $('<label>')
                  .attr('for', 'issue_status_stage')
                  .text('#{l(:field_stage)}');
                $stageP = $('<p>').addClass('tx-stage-field').append($stageLabel, $select);
              }

              var $pausedP = $('p.tx-paused-field').first();
              if (!$pausedP.length) {
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

                $pausedP = $('<p>').addClass('tx-paused-field').append($pausedLabel, $hidden, $checkbox);
              }

              var $descriptionP = $('p label[for="issue_status_description"]').parent();
              var $closedP = $('p label[for="issue_status_is_closed"]').parent();
              if (!$closedP.length) return;

              var $doneRatioP = $('p label[for="issue_status_default_done_ratio"]').parent();
              if (!$doneRatioP.length && #{show_default_done_ratio.to_json}) {
                $doneRatioP = $(#{str_default_done_ratio.to_json});
                if ($descriptionP.length) {
                  $descriptionP.after($doneRatioP);
                } else {
                  $closedP.before($doneRatioP);
                }
              }

              $doneRatioP = $('p label[for="issue_status_default_done_ratio"]').parent();
              if ($doneRatioP.length) {
                $stageP.insertBefore($doneRatioP);
              } else {
                $stageP.insertBefore($closedP);
              }
              $pausedP.insertBefore($closedP);
            }, 0);
          });
        </script>
EOS
      end
    end

    o
  end
end
