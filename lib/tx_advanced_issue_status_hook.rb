class TxAdvancedIssueStatusHook < Redmine::Hook::ViewListener
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
        o += <<EOS
        <script>
          var stage_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status|  issue_status.stage ? l(TxAdvancedIssueStatusHelper::STAGE_OPTIONS[issue_status.stage]) : '' }.to_json };
          var is_paused_values = #{ context[:controller].instance_variable_get(:@issue_statuses).map { |issue_status| issue_status.is_paused? }.to_json };
          $(function() {
            var $table = $('table.issue_statuses');
            if (!$table.length) return;

            // 헤더: td.name(상태) 뒤에 단계, is_closed(완료) 앞에 일시정지
            var $nameHeader = $table.find('thead th:first');
            var $closedHeader = $table.find('thead th').filter(function() {
              return $(this).text().trim() === '#{l(:field_is_closed)}';
            });
            if (!$nameHeader.length || !$closedHeader.length) return;

            var $stageHeader = $('<th>').text('#{l(:field_stage)}');
            var $pausedHeader = $('<th>').text('#{l(:field_is_paused)}');
            $nameHeader.after($stageHeader);
            $closedHeader.before($pausedHeader);

            // 바디: td.name 뒤에 단계, td.description 앞(=완료상태 앞)에 일시정지
            $table.find('tbody tr').each(function(index) {
              var $row = $(this);
              var $nameCell = $row.find('td.name');
              var $descCell = $row.find('td.description');
              if (!$nameCell.length || !$descCell.length) return;

              $nameCell.after($('<td>').text(stage_values[index]));
              $descCell.prev().before($('<td>').html(is_paused_values[index] ? '&#10003;' : ''));
            });
          });
        </script>
EOS
      elsif ['edit', 'new'].include?(context[:request].params[:action])
        issue_status = context[:controller].instance_variable_get(:@issue_status)

        o += <<EOS
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

            var $closedP = $('p label[for="issue_status_is_closed"]').parent();
            var $doneRatioP = $('p label[for="issue_status_default_done_ratio"]').parent();
            if ($doneRatioP.length) {
              $doneRatioP.before($stageP);
            } else {
              $closedP.before($stageP);
            }
            $closedP.before($pausedP);
          });
        </script>
EOS
      end
    end

    o
  end
end
