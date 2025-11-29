class QuestionGeneratorService
  attr_reader :interview_session, :questions

  def self.call(interview_session)
    new(interview_session).call
  end

  def initialize(interview_session)
    @interview_session = interview_session
    @questions = []
  end

  def call
    generate_questions
    save_questions
    questions
  end

  private

  def generate_questions
    response = OpenaiClientService.call(
      messages: build_messages,
      max_tokens: 2500
    )

    parse_questions(response)
  end

  def build_messages
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
      You are an expert technical interviewer with deep knowledge in #{interview_session.interview_category} interviews.
      Your task is to create high-quality, UNIQUE interview questions for a #{interview_session.position_level} level candidate.

      Interview Context:
      - Position: #{interview_session.title}
      - Level: #{interview_session.position_level}
      - Category: #{interview_session.interview_category}
      #{job_url_context}
      #{custom_requirements_context}

      Guidelines:
      - Questions MUST be unique and NOT commonly asked generic questions
      - Questions should be appropriate for the position level
      - Mix theoretical and practical questions
      - Include varying difficulty levels
      - Make questions specific and actionable
      - Focus on real-world scenarios when possible
      - Avoid cliché questions like "Tell me about yourself" or "What are your strengths/weaknesses"
      - Create thought-provoking questions that assess deep understanding
    PROMPT
  end

  def user_prompt
    questions_count = interview_session.questions_count || 5

    <<~PROMPT
      Generate exactly #{questions_count} UNIQUE and SPECIFIC interview questions for this position.

      Requirements:
      - Number each question (1-#{questions_count})
      - Each question should be on a new line
      - Questions should be clear and concise
      - Appropriate for #{interview_session.position_level} level
      - Focus on #{interview_session.interview_category} topics
      - Each question MUST be unique and not a generic/common interview question
      - Questions should be thought-provoking and assess deep understanding
      #{custom_requirements_instructions}

      Format:
      1. [First question]
      2. [Second question]
      ...
      #{questions_count}. [Last question]

      Generate the questions now.
    PROMPT
  end

  def job_url_context
    return "" unless interview_session.job_url.present?
    "\n- Job Posting URL: #{interview_session.job_url}"
  end

  def custom_requirements_context
    return "" unless interview_session.custom_requirements.present?
    "\n- Custom Requirements: #{interview_session.custom_requirements}"
  end

  def custom_requirements_instructions
    return "" unless interview_session.custom_requirements.present?
    "\n- IMPORTANT: Incorporate these specific requirements: #{interview_session.custom_requirements}"
  end

  def parse_questions(response)
    questions_count = interview_session.questions_count || 5

    # Split response by lines and extract numbered questions
    lines = response.split("\n").map(&:strip).reject(&:blank?)

    lines.each do |line|
      # Match lines that start with a number followed by a dot or parenthesis
      if line.match?(/^\d+[\.\)]\s+/)
        # Remove the number prefix
        question_text = line.sub(/^\d+[\.\)]\s+/, '').strip
        @questions << question_text if question_text.present?
      end
    end

    # Ensure we have exactly the requested number of questions
    @questions = @questions.first(questions_count)
  end

  def save_questions
    questions.each do |question_content|
      interview_session.questions.create!(content: question_content)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to save questions: #{e.message}")
    raise
  end
end

