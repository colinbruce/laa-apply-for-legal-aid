# frozen_string_literal: true

Rails.configuration.x.application.mock_saml = OpenStruct.new(
  users: [
    OpenStruct.new(username: 'test1', email: 'test1@example.com'),
    OpenStruct.new(username: 'test2', email: 'test2@example.com'),
    OpenStruct.new(username: 'test3', email: 'really-really-long-email-address@example.com')
  ],
  password: 'password'
)
