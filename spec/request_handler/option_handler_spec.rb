# frozen_string_literal: true
require 'spec_helper'
require 'request_handler/option_handler.rb'
describe RequestHandler::OptionHandler do
  it 'raises an error if allowed_option_types is not a dry type' do
    expect { described_class.new(params: { foo: 'bar' }, allowed_options_type: 'Fooo') }
      .to raise_error(RequestHandler::InternalArgumentError)
  end
end
