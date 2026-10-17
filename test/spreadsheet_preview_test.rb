# frozen_string_literal: true

require "minitest/autorun"
require "shellwords"
require "json"

unless defined?(RedmineMorePreviews::Conversion)
  module RedmineMorePreviews
    class Conversion; end
  end
end
unless defined?(Redmine::Platform)
  module Redmine
    module Platform
      def self.mswin?; false; end
    end
  end
end

require_relative "../lib/redmine_more_previews/spreadsheet_preview"
require_relative "../converters/libre/lib/libre"

class SpreadsheetPreviewTest < Minitest::Test
  def worker(format="pdf")
    result = Libre.allocate
    result.define_singleton_method(:preview_format) { format }
    result.define_singleton_method(:tmpdir) { "/tmp/conversion result" }
    result.define_singleton_method(:shell_quote) { |value| Shellwords.escape(value) }
    result
  end

  def test_spreadsheet_formats_use_calc_whole_sheet_export
    %w[xls XLSX xlsm xltm xltx ods fods ots sdc stc sxc csv].each do |extension|
      command = worker.pdf_export_format("/tmp/source.#{extension}")
      format, filter, options = command.split(":", 3)
      assert_equal "pdf", format
      assert_equal "calc_pdf_Export", filter
      assert_equal({"SinglePageSheets" => {"type"=>"boolean", "value"=>"true"}}, JSON.parse(options))
    end
  end

  def test_documents_and_other_outputs_keep_original_filter
    %w[docx doc rtf pptx odp odt pdf].each do |extension|
      assert_equal "pdf", worker.pdf_export_format("/tmp/source.#{extension}")
    end
    %w[html txt png jpg].each do |format|
      assert_equal format, worker(format).pdf_export_format("/tmp/source.xlsx")
    end
  end

  def test_json_and_source_path_remain_single_shell_arguments
    source = "/tmp/John's report & draft $(touch ignored).xlsx"
    Redmine::Platform.stub(:mswin?, false) do
      command = Shellwords.split(worker.soffice(source, "/tmp/lo-profile"))
      filter = command.fetch(command.index("--convert-to") + 1)
      assert_equal worker.pdf_export_format(source), filter
      assert_equal source, command.last
      assert_equal "/tmp/conversion result", command.fetch(command.index("--outdir") + 1)
    end
  end

  def test_windows_command_uses_the_same_filter
    Redmine::Platform.stub(:mswin?, true) do
      command = Shellwords.split(worker.soffice("/tmp/source.xlsx", "/tmp/lo-profile"))
      assert_equal worker.pdf_export_format("/tmp/source.xlsx"), command.fetch(command.index("--convert-to") + 1)
      refute command.any? { |arg| arg.start_with?("-env:UserInstallation=") }
    end
  end

end
