# frozen_string_literal: true
require 'minitest/autorun'
module RedmineMorePreviews
  module ControllerHelper; end
end
class AttachmentsController
  def self.accept_api_auth(*actions)
    @api_actions = actions unless actions.empty?
    @api_actions || []
  end
  def self.before_action(name, options)
    (@callbacks ||= []) << [name, options]
  end
  def self.callbacks; @callbacks; end
  accept_api_auth :show, :download, :thumbnail, :upload, :update, :destroy
  def find_attachment; end
  def read_authorize; end
end
require_relative '../lib/redmine_more_previews/patches/attachments_controller_patch'
class PreviewApiAuthTest < Minitest::Test
  def test_pdf_auth_extends_the_existing_actions_only
    assert_equal [:show, :download, :thumbnail, :upload, :update, :destroy, :more_preview], AttachmentsController.accept_api_auth
    refute_includes AttachmentsController.accept_api_auth, :more_asset
  end
  def test_existing_attachment_lookup_and_visibility_checks_remain
    [:find_attachment_for_more_preview, :read_authorize_for_more_preview].each do |name|
      callback = AttachmentsController.callbacks.find { |entry| entry.first == name }
      assert_includes callback.last[:only], :more_preview
    end
  end
end
