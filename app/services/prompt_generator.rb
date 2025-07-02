class PromptGenerator
  def initialize(failures:)
    @failures = failures
    @base_file_path = "/Users/seano/code/zipline-app/"
  end

  def generate
    failure = @failures.first
    return "No failures available." unless failure

    file_path = failure["file"]
    line_number = extract_line_number(failure["message"])
    return "Could not extract file path or line number for unknown reasons." unless file_path && line_number

    test_source = extract_test_source(file_path, line_number.to_i)
    return "Could not extract test source from file." unless test_source

    build_prompt(failure, test_source)
  end

private

  def extract_line_number(message)
    match = message.match(/\.rb:(\d+)/)
    match[1].to_i if match
  end

  def extract_test_source(file_path, line_number)
    absolute_path = Rails.root.join(@base_file_path, file_path)
    return unless File.exist?(absolute_path)

    lines = File.readlines(absolute_path)
    start = line_number - 1

    start -= 1 while start >= 0 && !lines[start].strip.start_with?("test", "def", "it")

    return unless start >= 0

    depth = 0
    finish = start
    lines[start..].each_with_index do |line, idx|
      depth += line.scan(/\b(do|def|if|case|begin|class|module|unless|while|until|for|loop|test)\b/).size
      depth -= line.scan(/\bend\b/).size
      finish = start + idx
      break if depth <= 0
    end

    lines[start..finish].join
  end

  def build_prompt(failure, source)
    <<~PROMPT
      A test in the file `#{failure['file']}` failed. The test name is:

      #{failure['name']}

      The error message was:

      #{failure['message']}

      Here's the test source:

      ```ruby
      #{source}
      ```

      Please explain what this failure likely means and suggest next steps for debugging or fixing it.
    PROMPT
  end
end
