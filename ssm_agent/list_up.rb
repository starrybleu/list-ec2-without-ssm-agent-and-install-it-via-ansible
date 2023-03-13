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
        return puts 'No instances found.' if response.count.zero?

        puts 'Instances -- ID, state:'
        # puts "#{response.first.data}"

        response.map(&:data)
                .group_by { |i| i[:key_name] }
                .each do |ssh_key_name, instances|
          puts "[[[[ ssh_key_name : #{ssh_key_name} ]]]]"
          instances.filter { |i| i.state.name == 'running' }
            .each do |instance_data|
            puts "#{ssh_key_name}, #{instance_data.instance_id}, #{instance_data.private_ip_address},  #{instance_data.state}, #{instance_data.platform}, #{instance_data.architecture}"
          end
        end
      rescue StandardError => e
        puts "Error getting information about instances: #{e.message}"
      end
    end
  end
end
