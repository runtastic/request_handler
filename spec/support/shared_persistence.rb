require "spec_helper"
require "dry/request_handler/base"
shared example "correct persistent object with different types of otions (proc, hash etc" do
  let(:n) {2}
  let(:request) do #TODO Fix Redundancy
    instance_double("Rack::Request",
                    params: params,
                    env:    {},
                    body:   StringIO.new(""))
  end
    let(:runstub) { double("Handler", run: { foo: "bar" }) }
  let(:testclass) do
    Class.new(Dry::RequestHandler::Base) do
      options do
        yield(class_context)
      end
    end
  end

  it "persists for the same instance" do
    instance = testclass.new(request: request)
    expect(tested_handler).to receive(:new).once.and_return(runstub)
    n.times { instance.send(:tested_method) }
  end

  it "does not persist for different instances" do
    instances = Array.new
    n.times { instances << testclass.new}
    expect(tested_handler).to receive(:new).exactly(n).times.and_return(runstub)
    instances.each {|instance| instance.send(:tested_methode) }
  end

end