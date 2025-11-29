class FeedbackGeneratorService
  attr_reader :interview_session

  def self.call(interview_session)
    new(interview_session).call
  end

  def initialize(interview_session)
    @interview_session = interview_session
  end

  def call
    generate_overall_feedback
  end

  private

  def generate_overall_feedback
    overall_data = generate_session_feedback
    
    interview_session.create_overall_feedback!(
      overall_score: overall_data[:overall_score],
      summary: overall_data[:summary],
      key_strengths: overall_data[:key_strengths],
      areas_for_improvement: overall_data[:areas_for_improvement],
      recommendations: overall_data[:recommendations]
    )
  end

  def generate_session_feedback
    response = OpenaiClientService.call(
      messages: build_feedback_messages,
      max_tokens: 2000
    )

    parse_feedback(response)
  end

  def build_feedback_messages
    [
      {
        role: "system",
        content: system_prompt
      },
      {
        role: "user",
        content: user_prompt
      }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are an expert interview coach providing comprehensive feedback on an entire interview session.
      Analyze all the questions and answers from the interview and provide:
      1. An overall score (0-100) based on:
         - Communication clarity
         - Answer completeness
         - Relevance to questions
         - Professional presentation
      2. A summary of the overall interview performance
      3. Key strengths demonstrated across all answers
      4. Areas for improvement
      5. Specific actionable recommendations for future interviews

      Be constructive, specific, and encouraging while being honest about areas needing improvement.

      IMPORTANT FORMATTING RULES:
      - For "key_strengths", "areas_for_improvement", and "recommendations" fields:
        * If providing multiple points, number them (1. 2. 3.)
        * Put EACH numbered item on a NEW LINE
        * Use this exact format:
          1. First point here
          2. Second point here
          3. Third point here
        * DO NOT put multiple numbered items in the same line
        * DO NOT use inline numbering like "1. First 2. Second 3. Third"

      Format your response as JSON:
      {
        "overall_score": 75,
        "summary": "Overall performance summary highlighting main observations...",
        "key_strengths": "1. First strength here\\n2. Second strength here\\n3. Third strength here",
        "areas_for_improvement": "1. First area here\\n2. Second area here\\n3. Third area here",
        "recommendations": "1. First recommendation here\\n2. Second recommendation here\\n3. Third recommendation here"
      }

      Note: Use \\n for line breaks in the JSON string values.
    PROMPT
  end

  def user_prompt
    questions_and_answers = interview_session.questions.includes(:answer).map.with_index do |question, index|
      answer_text = question.answer&.transcription || "No answer provided"
      
      <<~QA
        Question #{index + 1}: #{question.content}
        Answer: #{answer_text}
      QA
    end.join("\n---\n")

    <<~PROMPT
      Interview Session: #{interview_session.title}
      Position Level: #{interview_session.position_level}
      Category: #{interview_session.interview_category}
      Total Questions: #{interview_session.questions.count}
      
      Questions and Answers:
      #{questions_and_answers}
      
      Please provide comprehensive overall feedback for this entire interview session.
    PROMPT
  end

  def parse_feedback(response)
    json_match = response.match(/\{[\s\S]*\}/)
    return default_feedback unless json_match

    feedback = JSON.parse(json_match[0])
    {
      overall_score: feedback["overall_score"].to_i,
      summary: feedback["summary"],
      key_strengths: feedback["key_strengths"],
      areas_for_improvement: feedback["areas_for_improvement"],
      recommendations: feedback["recommendations"]
    }
  rescue JSON::ParserError
    default_feedback
  end

  def default_feedback
    {
      overall_score: 50,
      summary: "Interview completed with #{interview_session.questions.count} questions answered.",
      key_strengths: "Completed all questions in the interview session.",
      areas_for_improvement: "Could not generate detailed feedback at this time.",
      recommendations: "Review your answers and practice more interviews to improve your skills."
    }
  end
end

