class ReplyOfCommand

  @restautant_list = [
    '懷舊',
    '嚼舌'
  ]

  def self.call(command)
    reply = ''
    case command
    when 'shops'
      @restautant_list.each_with_index do |restrant, index|
        reply += "#{index}. #{restrant} \n"
      end
    end
  end
end
