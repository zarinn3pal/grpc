# Copyright 2026 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module GRPC
  module Core
    # CallCredentials represents per-call credentials.
    class CallCredentials
      attr_reader :auth_proc

      def initialize(auth_proc = nil, &block)
        @auth_proc = auth_proc || block
        fail TypeError, 'Argument to CallCredentials#new must be a proc' unless @auth_proc.is_a?(Proc)
      end

      def get_metadata(context)
        @auth_proc.call(context)
      end

      def compose(*others)
        return self if others.empty?
        others.each do |o|
          unless o.is_a?(CallCredentials) || o.is_a?(CompositeCallCredentials)
            fail TypeError, 'Argument to compose must be a CallCredentials'
          end
        end
        CompositeCallCredentials.new([self] + others)
      end
    end

    class CompositeCallCredentials < CallCredentials
      # rubocop:disable Lint/MissingSuper
      def initialize(*creds)
        @creds = creds.flatten
      end
      # rubocop:enable Lint/MissingSuper

      def get_metadata(context)
        metadata = {}
        @creds.each do |c|
          metadata.merge!(c.get_metadata(context))
        end
        metadata
      end

      def compose(*others)
        return self if others.empty?
        others.each do |o|
          unless o.is_a?(CallCredentials) || o.is_a?(CompositeCallCredentials)
            fail TypeError, 'Argument to compose must be a CallCredentials'
          end
        end
        CompositeCallCredentials.new(@creds + others)
      end
    end

    class Call
      def set_credentials!(credentials)
        # No-op for backward compatibility, as credentials are now applied synchronously
        # in ClientStub.
        @credentials = credentials
      end
    end
  end
end
