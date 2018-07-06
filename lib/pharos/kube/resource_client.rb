module Pharos
  module Kube
    class ResourceClient
      # @param transport [Pharos::Kube::Transport]
      # @param api_client [Pharos::Kube::APIClient]
      # @param api_resource [Pharos::Kube::API::MetaV1::APIResource]
      # @param namespace [String]
      def initialize(transport, api_client, api_resource, namespace: nil)
        @transport = transport
        @api_client = api_client
        @api_resource = api_resource
        @namespace = namespace

        fail "Resource #{api_resource.name} is not namespaced" if namespace unless api_resource.namespaced
      end

      # @return [String, nil]
      def namespace
        @namespace
      end

      # @return [String]
      def name
        @api_resource.name
      end

      # @return [String]
      def kind
        @api_resource.kind
      end

      # @return [Bool]
      def namespaced?
        !!@api_resource.namespaced
      end

      # @return [String]
      def path(*path, namespace: @namespace)
        if namespace
          @api_client.path('namespaces', namespace, @api_resource.name, *path)
        else
          @api_client.path(@api_resource.name, *path)
        end
      end

      # @return [Bool]
      def get?
        @api_resource.verbs.include? 'get'
      end

      def get(name, namespace: @namespace)
        @transport.request(
          method: 'GET',
          path: self.path(name, namespace: namespace),
        )
      end

      # @return [Bool]
      def list?
        @api_resource.verbs.include? 'list'
      end

      # @return [Array]
      def list(namespace: @namespace)
        list = @transport.request(
          method: 'GET',
          path: self.path(namespace: namespace),
          response_class: Pharos::Kube::API::MetaV1::List,
        )
        list.items.map {|item|
          # XXX: hack because list items do not include kind/apiVersion
          item.merge(apiVersion: list.apiVersion, kind: list.kind.sub(/List$/, ''))
        }
      end
    end
  end
end