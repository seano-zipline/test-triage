class FailuresController < ApplicationController
  def new
    render :new
  end

  def create
    url = params[:circleci_url]
    token = params[:circleci_token]

    parsed = CircleCiUrlParser.parse(url)

    unless parsed
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error", locals: { message: "Invalid CircleCI URL." })
      return
    end

    client = CircleCi::Client.new(token: token)

    org = parsed[:org]
    repo = parsed[:repo]
    pipeline_number = parsed[:pipeline_number]

    begin
      failures = client.analyze_pipeline_failure(org:, repo:, pipeline_number:)
      pp "**** failures ****"
      pp failures

      result = "LLM suggests that the failure is because ur bad at writing tests lol"

      render turbo_stream: turbo_stream.replace("results", partial: "failures/result", locals: { result: result })
    rescue => e
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error", locals: { message: e.message })
    end
  end
end
