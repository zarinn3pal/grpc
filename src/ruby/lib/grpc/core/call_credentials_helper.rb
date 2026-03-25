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
    # Helper for resolving and applying call credentials.
    module CallCredentialsHelper
      def self.resolve(channel_call_creds, call_credentials)
        if channel_call_creds && call_credentials
          channel_call_creds.compose(call_credentials)
        else
          channel_call_creds || call_credentials
        end
      end

      def self.apply(credentials, metadata, host, channel_creds)
        return unless credentials
        return if channel_creds == :this_channel_is_insecure

        context = { service_url: host }
        begin
          creds_metadata = credentials.get_metadata(context)
          creds_metadata&.each do |k, v|
            metadata[k.to_s] = v.is_a?(Array) ? v.map(&:to_s) : v.to_s
          end
        rescue StandardError => e
          fail GRPC::Unavailable, "Call credentials failed: #{e.message}"
        end
      end
    end
  end
end
