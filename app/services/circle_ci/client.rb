module CircleCi
  class Client
    BASE_URL = "https://circleci.com/api/v2"

    def initialize(token:)
      @token = token
    end

    def get_pipeline_by_number(org:, repo:, pipeline_number:)
      url = "#{BASE_URL}/project/gh/#{org}/#{repo}/pipeline"
      response = request(:get, url)
      pipeline = response["items"].find { |p| p["number"] == pipeline_number.to_i }
      pipeline
    end

    private

      # fill in circle ci api calls here

      def request(method, url)
        response = HTTParty.send(method, url, headers: auth_headers)
        JSON.parse(response.body)
      end

      def auth_headers
        {
          "Authorization" => "Bearer #{@token}",
          "Content-Type" => "application/json"
        }
      end
  end
end
