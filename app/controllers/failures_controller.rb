class FailuresController < ApplicationController
  def new
    render :new
  end

  def create
    url = params[:circleci_url]
    token = ENV.fetch("CIRCLE_CI_TOKEN", nil)

    parsed = CircleCiUrlParser.parse(url)

    unless parsed
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error",
                                                           locals: { message: "Invalid CircleCI URL." })
      return
    end

    client = CircleCi::Client.new(token: token)

    org = parsed[:org]
    repo = parsed[:repo]
    pipeline_number = parsed[:pipeline_number]

    begin
      failures = client.analyze_pipeline_failure(org:, repo:, pipeline_number:)
      prompt = PromptGenerator.new(failures: failures[:tests]).generate

      chat = RubyLLM.chat
      response = chat.ask(prompt)
      suggestion = response.content

      render turbo_stream: turbo_stream.replace("results", partial: "failures/result", locals: { result: suggestion })
    rescue StandardError => e
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error", locals: { message: e.message })
    end
  end
end
