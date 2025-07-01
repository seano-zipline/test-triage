class FailuresController < ApplicationController
  def new
    render :new
  end

  def create
    url = params[:circleci_url]
    token = params[:circleci_token]

    parsed = CircleCiUrlParser.parse(url)

    # pp parsed

    unless parsed
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error", locals: { message: "Invalid CircleCI URL." })
      return
    end

    client = CircleCi::Client.new(token: token)
    begin
      # pipeline = client.get_pipeline_by_number(**parsed)

      result = "LLM suggests that the failure is because ur bad at writing tests lol"

      render turbo_stream: turbo_stream.replace("results", partial: "failures/result", locals: { result: result })
    rescue => e
      render turbo_stream: turbo_stream.replace("results", partial: "failures/error", locals: { message: e.message })
    end
  end
end
