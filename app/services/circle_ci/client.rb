module CircleCi
  class Client
    BASE_URL = "https://circleci.com/api/v2"
    include HTTParty

    def initialize(token:)
      @token = token
    end

    def analyze_pipeline_failure(org:, repo:, pipeline_number:)
      pipeline = find_pipeline_by_number(org:, repo:, pipeline_number:)
      return { error: "Pipeline not found" } unless pipeline

      failed_workflows = get_workflows(pipeline["id"]).fetch("items", []).select do |w|
        w["status"] == "failed"
      end
      return { error: "No failed workflows found" } if failed_workflows.empty?

      failures = failed_workflows.flat_map do |workflow|
        find_failed_tests_in_workflow(org:, repo:, workflow_id: workflow["id"])
      end

      failures.empty? ? { error: "No failed jobs found in failed workflows" } : { tests: failures }
    end

    private

      def find_pipeline_by_number(org:, repo:, pipeline_number:)
        url = "#{BASE_URL}/project/gh/#{org}/#{repo}/pipeline"
        paginate(url) do |page|
          page["items"].find { |p| p["number"] == pipeline_number.to_i }
        end
      end

      def find_failed_tests_in_workflow(org:, repo:, workflow_id:)
        jobs = get_jobs(workflow_id).fetch("items", [])
        failed_job = jobs.find { |j| j["status"] == "failed" || j["status"] == "failing" }
        return [] unless failed_job

        get_failed_tests(org:, repo:, job_number: failed_job["job_number"])
      end

      def get_failed_tests(org:, repo:, job_number:)
        all_tests = get_all_tests(org:, repo:, job_number:)
        all_tests.select { |test| test["result"] == "failure" }
      end

      def get_all_tests(org:, repo:, job_number:)
        url = "#{BASE_URL}/project/gh/#{org}/#{repo}/#{job_number}/tests"
        collect_paginated_items(url)
      end

      def get_workflows(pipeline_id)
        request("#{BASE_URL}/pipeline/#{pipeline_id}/workflow")
      end

      def get_jobs(workflow_id)
        request("#{BASE_URL}/workflow/#{workflow_id}/job")
      end

      def collect_paginated_items(url)
        items = []
        paginate(url) { |page| items.concat(page["items"] || []) }
        items
      end

      def paginate(url)
        page_token = nil

        loop do
          full_url = page_token ? "#{url}?page-token=#{page_token}" : url
          page = request(full_url)

          result = yield(page)
          return result if result

          page_token = page["next_page_token"]
          break unless page_token
        end

        nil
      end

      def request(url)
        response = HTTParty.get(url, headers: auth_headers)
        JSON.parse(response.body)
      end

      def auth_headers
        encoded = Base64.strict_encode64("#{@token}:")
        {
          "Authorization" => "Basic #{encoded}",
          "Content-Type" => "application/json"
        }
      end
  end
end
