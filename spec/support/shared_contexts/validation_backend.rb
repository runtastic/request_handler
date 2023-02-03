# frozen_string_literal: true

shared_context "with dry validation engine" do
  around do |example|
    original_engine = RequestHandler.configuration.validation_engine
    RequestHandler.configuration.validation_engine = RequestHandler::Validation::DryEngine

    example.run

    RequestHandler.configuration.validation_engine = original_engine
  end
end

shared_context "with definition validation engine" do
  around do |example|
    require "request_handler/validation/definition_engine"
    require "definition"
    original_engine = RequestHandler.configuration.validation_engine
    RequestHandler.configuration.validation_engine = RequestHandler::Validation::DefinitionEngine

    example.run

    RequestHandler.configuration.validation_engine = original_engine
  end
end
