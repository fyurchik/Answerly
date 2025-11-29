module FeedbacksHelper
  def format_feedback_text(text, color_theme = 'primary')
    return '' if text.blank?

    # split inline numbered lists into separate lines
    normalized_text = normalize_inline_lists(text)

    lines = normalized_text.split("\n").map(&:strip).reject(&:blank?)
    is_numbered_list = lines.any? { |line| line.match?(/^\d+[\.\)]\s+/) }

    if is_numbered_list
      render_numbered_list(lines, color_theme)
    else
      content_tag(:p, text, class: 'text-body-color leading-relaxed')
    end
  end

  private

  def normalize_inline_lists(text)
    text.gsub(/\s+(\d+[\.\)])\s+/, "\n\\1 ")
  end

  def render_numbered_list(lines, color_theme)
    icon_config = theme_config(color_theme)
    
    content_tag(:div, class: 'space-y-3') do
      lines.map do |line|
        if line.match?(/^\d+[\.\)]\s+/)
          item_text = line.sub(/^\d+[\.\)]\s+/, '').strip
          render_list_item(item_text, icon_config)
        else
          content_tag(:p, line, class: 'text-body-color leading-relaxed')
        end
      end.join.html_safe
    end
  end

  def render_list_item(text, config)
    content_tag(:div, class: 'flex items-start space-x-3 group') do
      icon_html = content_tag(:div, class: "flex-shrink-0 w-8 h-8 #{config[:bg]} rounded-lg flex items-center justify-center mt-0.5") do
        content_tag(:svg, class: "w-4 h-4 #{config[:color]}", fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24') do
          tag.path(
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
            'stroke-width': '2',
            d: 'M9 5l7 7-7 7'
          )
        end
      end
      
      text_html = content_tag(:p, text, class: 'flex-1 text-body-color leading-relaxed pt-1')
      
      icon_html + text_html
    end
  end

  def theme_config(color_theme)
    themes = {
      'success' => { color: 'text-success', bg: 'bg-success-bg-light' },
      'warning' => { color: 'text-warning-dark', bg: 'bg-warning-bg' },
      'info' => { color: 'text-info', bg: 'bg-info-bg' },
      'primary' => { color: 'text-primary', bg: 'bg-primary-bg-light' }
    }
    
    themes[color_theme] || { color: 'text-primary', bg: 'bg-gray-2' }
  end
end

