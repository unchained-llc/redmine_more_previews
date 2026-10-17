# frozen_string_literal: true

module RedmineMorePreviews
  module SpreadsheetPreview
    EXTENSIONS = %w[csv fods ods ots sdc stc sxc xls xlsm xlsx xltm xltx].freeze

    def self.spreadsheet?(filename)
      EXTENSIONS.include?(File.extname(filename.to_s).delete_prefix(".").downcase)
    end
  end
end
