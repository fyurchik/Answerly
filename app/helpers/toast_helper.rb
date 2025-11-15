module ToastHelper
  def render_toast_notifications
    toasts = []
    
    if notice.present?
      toasts << { message: notice, type: 'notice' }
    end
    
    if alert.present?
      toasts << { message: alert, type: 'alert' }
    end
    
    return if toasts.empty?
    
    content_tag(:div, 
      class: "fixed top-4 right-4 z-50",
      data: { 
        controller: "toast"
      }
    ) do
      content_tag(:div, "", data: { toast_target: "container" }) +
      toasts.map do |toast|
        content_tag(:div, "",
          data: {
            controller: "toast",
            toast_message_value: toast[:message],
            toast_type_value: toast[:type],
            toast_duration_value: 5000
          }
        )
      end.join.html_safe
    end
  end
end

