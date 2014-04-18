require 'test_helper'
require 'rack'
require 'json'
require File.expand_path('../live_test_server.rb', __FILE__)

unless !!ENV['NO_LIVE']

  describe HyperResource do
    class WhateverJSONAPI < HyperResource; end

    if RUBY_VERSION[0..2] == '1.8'
      it 'does not run live tests on 1.8' do
        puts "Live tests don't run on Ruby 1.8, skipping."
      end
    else

      before do
        @port = ENV['HR_TEST_PORT'] || (20000 + rand(10000))

        @server_thread = Thread.new do
          Rack::Handler::WEBrick.run(
            LiveTestServer.new,
            :Port => @port,
            :AccessLog => [],
            :Logger => WEBrick::Log::new("/dev/null", 7)
          )
        end

        @api = WhateverJSONAPI.new(:root => "http://localhost:#{@port}/json-api/", adapter: HyperResource::Adapter::JSON_API)

        begin # block until server is ready
          @api.get
        rescue Faraday::ConnectionFailed => e
          sleep(0.2) and retry
        end
      end

      after do
        @server_thread.kill
      end

      describe 'live tests' do
        it 'works at all' do
          root = @api.get
          root.wont_be_nil
          root.name.must_equal 'Fruits Basket API'
          root.must_be_kind_of HyperResource
          root.must_be_instance_of WhateverJSONAPI::Root
        end

        it 'follows links' do
          root = @api.get
          root.links.must_respond_to :baskets
          baskets = root.baskets.get
          baskets.must_be_kind_of HyperResource
          baskets.must_be_instance_of WhateverJSONAPI::BasketSet
        end

        it 'observes proper classing' do
          root = @api.get
          root.must_be_instance_of WhateverJSONAPI::Root
          root.links.must_be_instance_of WhateverJSONAPI::Root::Links
          root.attributes.must_be_instance_of WhateverJSONAPI::Root::Attributes

          root.baskets.must_be_instance_of WhateverJSONAPI::Root::Link
        end

        it 'passes headers to sub-objects' do
          @api.headers['X-Type'] = 'Foobar'
          root = @api.get
          widget = root.baskets.get.first
          widget.headers['X-Type'].must_equal 'Foobar'
        end

        describe "invocation styles" do
          it 'can use HyperResource with no namespace' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/json-api/", adapter: HyperResource::Adapter::JSON_API)
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'HyperResource'
          end

          it 'can use HyperResource with a namespace' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/json-api/",
                                    :namespace => 'NsTestApi', adapter: HyperResource::Adapter::JSON_API)
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'NsTestApi::Root'
          end

          class NsExtTestApi < HyperResource
            class Root < NsExtTestApi
              def foo; :foo end
            end
          end
          it 'can use HyperResource with a namespace which is extended' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/json-api/",
                                    :namespace => 'NsExtTestApi', adapter: HyperResource::Adapter::JSON_API)
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'NsExtTestApi::Root'
            root.must_respond_to :foo
            root.foo.must_equal :foo
          end
        end

        describe 'configuration testing' do
          before do
            @api_short = WhateverJSONAPI.new(
              :root => "http://localhost:#{@port}/json-api/",
              :faraday_options => {
                :request => {:timeout => 0.001}
              }
            )
          end

          it 'passes the configuration to subclasses' do
            api_short_child = @api_short.get
            api_short_child.faraday_options[:request][:timeout].must_equal 0.001
          end
        end


      end # describe 'live tests'

    end # if
  end # describe HyperResource

end

