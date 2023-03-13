require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

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
          puts "[[[[ ssh_key_name : #{ssh_key_name}, count: #{instances.size} ]]]]"
          puts "[#{ssh_key_name}]"
          instances_running_without_ssm_agent = instances.filter { |i| i.state.name == 'running' }
                         .filter do |i|
            sleep(0.2) # Rate exceeded 오류 방지
            !ssm_enabled?(i.instance_id)
          end
          puts "instances_running_without_ssm_agent.size: #{instances_running_without_ssm_agent.size}"
          instances_running_without_ssm_agent
                   .each_with_index do |instance_data, idx|
            # puts "#{idx}, #{ssh_key_name}, #{instance_data.instance_id}, #{instance_data.private_ip_address},  #{instance_data.state.name}, #{instance_data.platform}, #{instance_data.architecture}"
            puts "#{instance_data.private_ip_address}"
          end
          puts
          puts("[#{ssh_key_name}:vars]")
          puts("ansible_ssh_user=ec2-user")
          puts("ansible_ssh_private_key_file=/home/ec2-user/.ssh/#{ssh_key_name}.pem")
          puts
        end
      rescue StandardError => e
        puts "Error getting information about instances: #{e.message}"
      end

      def ssm_enabled?(ec2_id)
        @client ||= Aws::SSM::Client.new
        response = @client.describe_instance_information({
                                                           instance_information_filter_list: [
                                                             {
                                                               key: 'InstanceIds',
                                                               value_set: [ec2_id]
                                                             }
                                                           ],
                                                           max_results: 5
                                                         })
        return false unless response.next_token.nil?
        return false if response.first.nil?
        return false if response.first.instance_information_list.nil?
        return false if response.first.instance_information_list[0].nil?

        var = response.first.instance_information_list[0][:association_status]
        var == 'Success'
      end
    end
  end
end
