# frozen_string_literal: true
Dry::RequestHandler.configure  do
  logger Logger.new(STDOUT)
end
