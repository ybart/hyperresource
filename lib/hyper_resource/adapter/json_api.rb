require 'rubygems' if RUBY_VERSION[0..2] == '1.8'
require 'json'

class HyperResource
  class Adapter

    ## HyperResource::Adapter::JSON_JSON provides support for the JSON API
    ## hypermedia format by implementing the interface defined in
    ## HyperResource::Adapter.

    class JSON_API < Adapter
      class << self

        def serialize(object)
          JSON.dump(object)
        end

        def deserialize(string)
          JSON.parse(string)
        end

        def apply(response, resource, opts={})
          if !response.kind_of?(Hash)
            raise ArgumentError, "'response' argument must be a Hash"
          end
          if !resource.kind_of?(HyperResource)
            raise ArgumentError, "'resource' argument must be a HyperResource"
          end

          resource.body = response
          Parser.new(resource).parse
          resource
        end
      end

      private

        class Parser
          def initialize resource
            @response = resource.body
            @resource = resource
            @klass = resource.class
            @document_key = nil
          end

          def parse
            build_top_documents
            build_linked_documents
            build_links @resource # Top-Level links
            build_document_links  # Needs both top and linked documents to be built.
            @resource.loaded = true
          end

          def document_key
            @document_key ||= (
              remaining_keys = @response.keys - ["meta", "links", "linked"]
              remaining_keys.first
            )
          end

          private
          def build_document object, type
            resource = @klass.new(
              :root => @resource.root,
              :headers => @resource.headers,
              :namespace => @resource.namespace
            )
            resource.attributes['_type'] = type
            resource.body = object
            resource.loaded = true

            build_attributes(resource, object)
            resource
          end

          def build_top_documents
            return unless @response[document_key]

            objects = @resource.objects ||= @klass::Objects.new(@resource)
            objects[document_key] = @response[document_key].map do |object|
              build_document(object, document_key)
            end

            objects._hr_create_methods!
          end

          def build_linked_documents
            return unless @response['linked']

            objects = @resource.objects ||= @klass::Objects.new(@resource)
            @response['linked'].each do |name, collection|
              objects[name] = collection.map do |object|
                build_document(object, name)
              end
            end

            objects._hr_create_methods!
          end

          def build_links resource
            return unless resource.body['links']
            links = resource.links = resource._hr_response_class::Links.new(resource)

            resource.body['links'].each do |name, link_spec|
              if link_spec.is_a? Hash
                links[name] = build_spec(resource, name, link_spec)
              elsif link_spec.is_a? Array
                links[name] = build_specs(resource, name, link_spec)
              else # Assumes it's an identifier
                links[name] = build_spec(resource, name, link_spec)
              end
            end

            links._hr_create_methods!
          end
          
          def build_document_links
            @resource.objects.each do |name, resources|
              resources.each { |resource| build_links resource }
            end
          end
          
          def build_specs parent, name, link_specs
            link_specs.map do |spec|
              build_spec parent, name, spec
            end
          end
          
          def build_spec parent, name, link_spec
            if link_spec.is_a? Hash
              link_spec['name'] = name
              link_spec['href'] ||= build_hrefs(name, link_spec)
              link_spec['templated'] = true
              parent.class::Link.new(parent, link_spec)
            else
              type = infer_type parent, name
              resource = @resource.objects[type].find { |r| r.attributes['id'] == link_spec }
              parent.objects[name] ||= []
              parent.objects[name] << resource
            end
          end

          def infer_type parent, name
            links = @response['links']
            type = (links["#{parent.attributes['_type']}.#{name}"] || links[name]) rescue nil
            type ||= name.pluralize rescue name
          end

          def build_attributes(resource, object)
            resource.attributes = resource._hr_response_class::Attributes.new(resource)

            given_attrs = object.reject{|k,_| k == 'links'}
            filtered_attrs = resource.incoming_body_filter(given_attrs)

            filtered_attrs.keys.each do |attr|
              resource.attributes[attr] = filtered_attrs[attr]
            end
            
            resource.attributes._hr_clear_changed
            resource.attributes._hr_create_methods!
          end
        end
    end
  end
end

