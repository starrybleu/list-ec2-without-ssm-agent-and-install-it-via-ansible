require 'aws-sdk-ec2'

module SsmAgent
  class ListUp
    class << self
      def list_up
        ec2_resource = Aws::EC2::Resource.new
        list_instance_ids_states(ec2_resource)
      end

      private

      def list_instance_ids_states(ec2_resource)
        response = ec2_resource.instances
        if response.count.zero?
          puts 'No instances found.'
        else
          puts 'Instances -- ID, state:'
          response.each_with_index do |instance, idx|
            puts "#{idx}, #{instance.id}, #{instance.state.name}"
          end
        end
      rescue StandardError => e
        puts "Error getting information about instances: #{e.message}"
      end
    end
  end
end
