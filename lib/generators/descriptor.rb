require 'yaml'

require_relative 'helpers/application'

module Obvious
  module Generators
    class Descriptor
      def initialize descriptor
        @descriptor = descriptor
      end

      def to_file
        action = YAML.load_file @descriptor
        @jacks, @entities = {}, {}
        @code = ''

        action['Code'].each do |entry|
          write_comments_for entry
          process_requirements_for entry if entry['requires']
        end

        write_action action
      end

      private
      def write_comments_for entry
        @code << "    \# #{entry['c']}\n"
        @code << "    \# use: #{entry['requires']}\n" if entry['requires']
        @code << "    \n"
      end

      def process_requirements_for entry
        app      = Obvious::Generators::Application.instance
        requires = entry['requires'].split ','

        requires.each do |req|
          req.strip!
          infos = req.split '.'

          if infos[0].index 'Jack'
            app.jacks[infos[0]] = [] unless app.jacks[infos[0]]
            @jacks[infos[0]]    = [] unless @jacks[infos[0]]

            app.jacks[infos[0]] << infos[1]
            @jacks[infos[0]] << infos[1]
          else
            app.entities[infos[0]] = [] unless app.entities[infos[0]]
            @entities[infos[0]]    = [] unless @entities[infos[0]]

            app.entities[infos[0]] << infos[1]
            @entities[infos[0]] << infos[1]
          end
        end
      end # #process_requirements_for

      def write_action action
        jacks_data   = process_jacks
        requirements = require_entities

        output = %Q{#{requirements}
class #{action['Action']}

  def initialize #{jacks_data[:inputs]}
#{jacks_data[:assignments]}  end

  def execute input
#{@code}  end
end
}

        snake_name = action['Action'].gsub(/(.)([A-Z])/,'\1_\2').downcase

        filename = "#{Obvious::Generators::Application.instance.dir}/actions/#{snake_name}.rb"
        File.open(filename, 'w') {|f| f.write(output) }
      end

      def process_jacks
        jack_inputs = ''
        jack_assignments = ''

        @jacks.each do |k, v|
          name = k.chomp('Jack').downcase
          jack_inputs << "#{name}_jack, "
          jack_assignments << "    @#{name}_jack = #{name}_jack\n"
        end

        jack_inputs.chomp! ', '

        {
          inputs: jack_inputs,
          assignments: jack_assignments
        }
      end

      def require_entities
        entity_requires = ''

        @entities.each do |k, v|
          name = k.downcase
          entity_requires << "require_relative '../entities/#{name}'\n"
        end

        entity_requires
      end
    end # ::Descriptor
  end
end
