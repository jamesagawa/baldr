class Baldr::FunctionalGroup < Baldr::Segment

  helpers_for_elements(
    'GS01' => :functional_identifier_code,
    'GS02' => :application_senders_code,
    'GS03' => :application_receivers_code,
    'GS04' => :date,
    'GS05' => :time,
    'GS06' => :group_control_number,
    'GS07' => :responsible_agency_code,
    'GS08' => :version_release_industry_code,
  )

  def initialize(id = 'GS')
    super(id)

    #self.application_senders_code = ''
    #self.application_receivers_code = ''
    self.date_time = DateTime.now
    self.responsible_agency_code = 'X'
    self.version_release_industry_code = '004010'
  end

  def prepare!
    trailer = get_trailer('GE')

    trailer['GE01'] = transaction_loop.segments.count.to_s

    self.group_control_number ||= generate_control_number(9)
    trailer['GE02'] = group_control_number
  end

  def sub_version
    Baldr::Grammar.for_version(version_release_industry_code)
  end

  def transactions
    transaction_loop.segments
  end

  def date_time
    DateTime.parse "#{date} #{time}"
  end

  def date_time=(value)
    self.date = value.strftime('%Y%m%d')
    self.time = value.strftime('%H%M')
  end

  def custom_validate!(version)
    transaction_loop.segments.each do |transaction|
      if version.for_transaction_set(transaction.transaction_set_code)::FUNCTIONAL_GROUP != functional_identifier_code
        raise "wrong transaction #{transaction.transaction_set_code} in functional group #{functional_identifier_code}"
      end
    end

    trailer = @children.second.segments.first
    if trailer['GE01'].to_i != transaction_loop.segments.count
      raise "wrong transactions number: #{trailer['GE01']} in GE01, but real number is #{transaction_loop.segments.count}"
    end
    if trailer['GE02'] != group_control_number
      raise "group control numbers don't match: #{trailer['GE02']} in GE02 and #{group_control_number} in GS06"
    end
  end

  protected

  def transaction_loop
    @children.first
  end

end