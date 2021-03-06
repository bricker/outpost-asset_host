module Outpost
  module AssetHost
    module JsonInput
      extend ActiveSupport::Concern

      module ClassMethods
        def accepts_json_input_for_assets
          include InstanceMethodsOnActivation
          @assets_association_join_class = self.reflect_on_association(:assets).class_name
        end

        def assets_association_join_class
          @assets_association_join_class
        end
      end


      module InstanceMethodsOnActivation
        #-------------------
        # #asset_json is a way to pass in a string representation
        # of a javascript object to the model, which will then be
        # parsed and turned into ContentAsset objects in the
        # #asset_json= method.
        def asset_json
          current_assets_json.to_json
        end

        #-------------------
        # Parse the input from #asset_json and turn it into real
        # ContentAsset objects.
        def asset_json=(json)
          # If this is literally an empty string (as opposed to an
          # empty JSON object, which is what it would be if there were no assets),
          # then we can assume something went wrong and just abort.
          # This shouldn't happen since we're populating the field in the template.
          return if json.empty?

          json = Array(JSON.parse(json)).sort_by { |c| c["position"].to_i }
          loaded_assets = []

          json.each do |asset_hash|
            new_asset = self.class.assets_association_join_class.constantize.new(
              :asset_id    => asset_hash["id"].to_i,
              :caption     => asset_hash["caption"].to_s,
              :position    => asset_hash["position"].to_i
            )

            loaded_assets.push new_asset
          end

          loaded_assets_json = assets_to_simple_json(loaded_assets)

          # If the assets didn't change, there's no need to bother the database.
          if current_assets_json != loaded_assets_json
            self.assets = loaded_assets
          end

          self.assets
        end


        private

        def current_assets_json
          assets_to_simple_json(self.assets)
        end

        def assets_to_simple_json(array)
          Array(array).map(&:simple_json)
        end
      end
    end
  end
end
