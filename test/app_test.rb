ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!
require "rack/test"
require "fileutils"
require "pry"

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    # skip

    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"

  end

  def test_about
    # skip

    create_document "about.txt", "random text about"

    get "/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_equal "random text about", last_response.body
  end

  def test_changes
    # skip

    create_document "changes.txt"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
  end

  def test_history
    # skip

    create_document "history.txt"

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
  end

  def test_document_not_found
    # skip

    get "/notafile.ext" # Attempt to access a nonexistent file

    assert_equal 302, last_response.status # Assert that the user was redirected

    get last_response["Location"] # Request the page that the user was redirected to

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"

    get "/" # Reload the page
    refute_includes last_response.body, "notafile.ext does not exist" # Assert that our message has been removed
  end

  def test_viewing_markdown_document
    # skip
    create_document "about.md", "<h1>A Markdown file</h1>"

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>A Markdown file</h1>"
  end

  # test/cms_test.rb
  def test_editing_document
    # skip

    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_updating_document
    # skip
    create_document "changes.txt"


    post "/files/changes.txt", editable_content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "The file 'changes.txt' has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end
