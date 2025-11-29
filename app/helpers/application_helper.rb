module ApplicationHelper
  def score_color(score)
    case score
    when 80..100
      'text-success'
    when 60..79
      'text-info'
    when 40..59
      'text-warning'
    else
      'text-error'
    end
  end
end
