class CircleCiUrlParser
  CIRCLECI_PIPELINE_REGEX = %r{
    ^https://app\.circle_ci\.com/pipelines/github/
    (?<org>[^/]+)/
    (?<repo>[^/]+)/
    (?<pipeline_number>\d+)
  }x

  def self.parse(url)
    match = CIRCLECI_PIPELINE_REGEX.match(url)
    return nil unless match

    {
      org: match[:org],
      repo: match[:repo],
      pipeline_number: match[:pipeline_number]
    }
  end
end
