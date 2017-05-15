# frozen_string_literal: true

describe RequestHandler do
  around do |example|
    default_config = RequestHandler.configuration.dup
    example.run
    RequestHandler.instance_variable_set('@configuration', default_config)
  end

  it 'has a working logger configured' do
    expect(RequestHandler.configuration.logger).to respond_to(:warn)
  end
  it 'has a separator configured' do
    expect(RequestHandler.configuration.separator).to eq('__')
  end
  it 'can be configured' do
    logger_double = instance_double('Logger')
    RequestHandler.configure do
      separator '____'
      logger logger_double
    end

    expect(RequestHandler.configuration.logger).to eq(logger_double)
    expect(RequestHandler.configuration.separator).to eq('____')
  end
end
