require 'time'
module AEMO
  class NEM12
    # As per AEMO NEM12 Specification
    # http://www.aemo.com.au/Consultations/National-Electricity-Market/Open/~/media/Files/Other/consultations/nem/Meter%20Data%20File%20Format%20Specification%20NEM12_NEM13/MDFF_Specification_NEM12_NEM13_Final_v102_clean.ashx
    RECORD_INDICATORS = {
      100 => 'Header',
      200 => 'NMI Data Details',
      300 => 'Interval Data',
      400 => 'Interval Event',
      500 => 'B2B Details',
      900 => 'End'
    }
    
    TRANSACTION_CODE_FLAGS = {
      'A' => 'Alteration',
      'C' => 'Meter Reconfiguration',
      'G' => 'Re-energisation',
      'D' => 'De-energisation',
      'E' => 'Forward Estimate',
      'N' => 'Normal Read',
      'O' => 'Other',
      'S' => 'Special Read',
      'R' => 'Removal of Meter'
    }
    
    UOM = {
      'MWh'   => { :name => 'Megawatt Hour', :multiplier => 1e6 },
      'kWh'   => { :name => 'Kilowatt Hour', :multiplier => 1e3 },
      'Wh'    => { :name => 'Watt Hour', :multiplier => 1 },
      'MW'    => { :name => 'Megawatt', :multiplier => 1e6 },
      'kW'    => { :name => 'Kilowatt', :multiplier => 1e3 },
      'W'     => { :name => 'Watt', :multiplier => 1 },
      'MVArh' => { :name => 'Megavolt Ampere Reactive Hour', :multiplier => 1e6 },
      'kVArh' => { :name => 'Kilovolt Ampere Reactive Hour', :multiplier => 1e3 },
      'VArh'  => { :name => 'Volt Ampere Reactive Hour', :multiplier => 1 },
      'MVAr'  => { :name => 'Megavolt Ampere Reactive', :multiplier => 1e6 },
      'kVAr'  => { :name => 'Kilovolt Ampere Reactive', :multiplier => 1e3 },
      'VAr'   => { :name => 'Volt Ampere Reactive', :multiplier => 1 },
      'MVAh'  => { :name => 'Megavolt Ampere Hour', :multiplier => 1e6 },
      'kVAh'  => { :name => 'Kilovolt Ampere Hour', :multiplier => 1e3 },
      'VAh'   => { :name => 'Volt Ampere Hour', :multiplier => 1 },
      'MVA'   => { :name => 'Megavolt Ampere', :multiplier => 1e6 },
      'kVA'   => { :name => 'Kilovolt Ampere', :multiplier => 1e3 },
      'VA'    => { :name => 'Volt Ampere', :multiplier => 1 },
      'kV'    => { :name => 'Kilovolt', :multiplier => 1e3 },
      'V'     => { :name => 'Volt', :multiplier => 1 },
      'kA'    => { :name => 'Kiloampere', :multiplier => 1e3 },
      'A'     => { :name => 'Ampere', :multiplier => 1 },
      'pf'    => { :name => 'Power Factor', :multiplier => 1 }
    }
    
    QUALITY_FLAGS = {
      'A'     => 'Actual Data',
      'E'     => 'Forward Estimated Data',
      'F'     => 'Final Substituted Data',
      'N'     => 'Null Data',
      'S'     => 'Substituted Data',
      'V'     => 'Variable Data',
    }
    
    METHOD_FLAGS = Hash[*((11..19).map{|i| [i,i]} + (51..58).map{|i| [i,i]} + (61..68).map{|i| [i,i]} + (71..75).map{|i| [i,i]}).flatten.map{|i| i.to_s}]
    
    REASON_CODES = {
      0 => 'Free Text Description',
      1 => 'Meter/Equipment Changed',
      2 => 'Extreme Weather/Wet',
      3 => 'Quarantine',
      4 => 'Savage Dog',
      5 => 'Meter/Equipment Changed',
      6 => 'Extreme Weather/Wet',
      7 => 'Unable To Locate Meter',
      8 => 'Vacant Premise',
      9 => 'Meter/Equipment Changed',
      10 => 'Lock Damaged/Seized',
      11 => 'In Wrong Walk',
      12 => 'Locked Premises',
      13 => 'Locked Gate',
      14 => 'Locked Meter Box',
      15 => 'Access - Overgrown',
      16 => 'Noxious Weeds',
      17 => 'Unsafe Equipment/Location',
      18 => 'Read Below Previous',
      19 => 'Consumer Wanted',
      20 => 'Damaged Equipment/Panel',
      21 => 'Switched Off',
      22 => 'Meter/Equipment Seals Missing',
      23 => 'Meter/Equipment Seals Missing',
      24 => 'Meter/Equipment Seals Missing',
      25 => 'Meter/Equipment Seals Missing',
      26 => 'Meter/Equipment Seals Missing',
      27 => 'Meter/Equipment Seals Missing',
      28 => 'Damaged Equipment/Panel',
      29 => 'Relay Faulty/Damaged',
      30 => 'Meter Stop Switch On',
      31 => 'Meter/Equipment Seals Missing',
      32 => 'Damaged Equipment/Panel',
      33 => 'Relay Faulty/Damaged',
      34 => 'Meter Not In Handheld',
      35 => 'Timeswitch Faulty/Reset Required',
      36 => 'Meter High/Ladder Required',
      37 => 'Meter High/Ladder Required',
      38 => 'Unsafe Equipment/Location',
      39 => 'Reverse Energy Observed',
      40 => 'Timeswitch Faulty/Reset Required',
      41 => 'Faulty Equipment Display/Dials',
      42 => 'Faulty Equipment Display/Dials',
      43 => 'Power Outage',
      44 => 'Unsafe Equipment/Location',
      45 => 'Readings Failed To Validate',
      46 => 'Extreme Weather/Hot',
      47 => 'Refused Access',
      48 => 'Timeswitch Faulty/Reset Required',
      49 => 'Wet Paint',
      50 => 'Wrong Tariff',
      51 => 'Installation Demolished',
      52 => 'Access - Blocked',
      53 => 'Bees/Wasp In Meter Box',
      54 => 'Meter Box Damaged/Faulty',
      55 => 'Faulty Equipment Display/Dials',
      56 => 'Meter Box Damaged/Faulty',
      57 => 'Timeswitch Faulty/Reset Required',
      58 => 'Meter Ok - Supply Failure',
      59 => 'Faulty Equipment Display/Dials',
      60 => 'Illegal Connection/Equipment Tampered',
      61 => 'Meter Box Damaged/Faulty',
      62 => 'Damaged Equipment/Panel',
      63 => 'Illegal Connection/Equipment Tampered',
      64 => 'Key Required',
      65 => 'Wrong Key Provided',
      66 => 'Lock Damaged/Seized',
      67 => 'Extreme Weather/Wet',
      68 => 'Zero Consumption',
      69 => 'Reading Exceeds Estimate',
      70 => 'Probe Reports Tampering',
      71 => 'Probe Read Error',
      72 => 'Meter/Equipment Changed',
      73 => 'Low Consumption',
      74 => 'High Consumption',
      75 => 'Customer Read',
      76 => 'Communications Fault',
      77 => 'Estimation Forecast',
      78 => 'Null Data',
      79 => 'Power Outage Alarm',
      80 => 'Short Interval Alarm',
      81 => 'Long Interval Alarm',
      82 => 'CRC Error',
      83 => 'RAM Checksum Error',
      84 => 'ROM Checksum Error',
      85 => 'Data Missing Alarm',
      86 => 'Clock Error Alarm',
      87 => 'Reset Occurred',
      88 => 'Watchdog Timeout Alarm',
      89 => 'Time Reset Occurred',
      90 => 'Test Mode',
      91 => 'Load Control',
      92 => 'Added Interval (Data Correction)',
      93 => 'Replaced Interval (Data Correction)',
      94 => 'Estimated Interval (Data Correction)',
      95 => 'Pulse Overflow Alarm',
      96 => 'Data Out Of Limits',
      97 => 'Excluded Data',
      98 => 'Parity Error',
      99 => 'Energy Type (Register Changed)'
    }
    
    DATA_STREAM_SUFFIX = {
      # Averaged Data Streams
      'A' => { :stream => 'Average', :description => 'Import', :units => 'kWh' },
      'D' => { :stream => 'Average', :description => 'Export', :units => 'kWh' },
      'J' => { :stream => 'Average', :description => 'Import', :units => 'kVAr' },
      'P' => { :stream => 'Average', :description => 'Export', :units => 'kVAr' },
      'S' => { :stream => 'Average', :description => '',       :units => 'kVAh' },
      # Master Data Streams
      'B' => { :stream => 'Master',  :description => 'Import', :units => 'kWh' },
      'E' => { :stream => 'Master',  :description => 'Export', :units => 'kWh' },
      'K' => { :stream => 'Master',  :description => 'Import', :units => 'kVAr' },
      'Q' => { :stream => 'Master',  :description => 'Export', :units => 'kVAr' },
      'T' => { :stream => 'Master',  :description => '',       :units => 'kVAh' },
      'G' => { :stream => 'Master',  :description => 'Power Factor',       :units => 'PF' },
      'H' => { :stream => 'Master',  :description => 'Q Metering',         :units => 'Qh' },
      'M' => { :stream => 'Master',  :description => 'Par Metering Path',  :units => '' },
      'V' => { :stream => 'Master',  :description => 'Volts or V2h or Amps or A2h',  :units => '' },
      # Check Meter Streams
      'C' => { :stream => 'Check',  :description => 'Import', :units => 'kWh' },
      'F' => { :stream => 'Check',  :description => 'Export', :units => 'kWh' },
      'L' => { :stream => 'Check',  :description => 'Import', :units => 'kVAr' },
      'R' => { :stream => 'Check',  :description => 'Export', :units => 'kVAr' },
      'U' => { :stream => 'Check',  :description => '',       :units => 'kVAh' },
      'Y' => { :stream => 'Check',  :description => 'Q Metering',         :units => 'Qh' },
      'W' => { :stream => 'Check',  :description => 'Par Metering Path',  :units => '' },
      'Z' => { :stream => 'Check',  :description => 'Volts or V2h or Amps or A2h',  :units => '' },
      # Net Meter Streams
      'D' => { :stream => 'Net',    :description => 'Net', :units => 'kWh' },
      'J' => { :stream => 'Net',    :description => 'Net', :units => 'kVAr' },
    }
    
    @nmi              = nil
    @data_details     = []
    @interval_data    = []
    @interval_events  = []
    
    attr_accessor :nmi, :file_contents
    attr_reader   :data_details, :interval_data, :interval_events
    
    # Initialize a NEM12 file
    def initialize(nmi,options={})
      @nmi              = nmi
      @data_details     = []
      @interval_data    = []
      @interval_events  = []
      options.keys.each do |key|
        eval "self.#{key} = #{options[key]}"
      end
    end
    
    # @return [Integer] checksum of the NMI
    def nmi_checksum
      summation = 0
      @nmi.reverse.split(//).each_index do |i|
        value = nmi[nmi.length - i - 1].ord
        if(i % 2 == 0)
          value = value * 2
        end
        value = value.to_s.split(//).map{|i| i.to_i}.reduce(:+)
        summation += value
      end      
      checksum = (10 - (summation % 10)) % 10
      checksum
    end

    # Parses the header record
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def self.parse_nem12_100(line)
      csv = line.parse_csv

      raise ArgumentError, 'RecordIndicator is not 100'     if csv[0] != '100'
      raise ArgumentError, 'VersionHeader is not NEM12'     if csv[1] != 'NEM12'
      raise ArgumentError, 'DateTime is not valid'          if csv[2].match(/\d{12}/).nil?  || csv[2] != Time.parse("#{csv[2]}00").strftime('%Y%m%d%H%M')
      raise ArgumentError, 'FromParticispant is not valid'  if csv[3].match(/.{1,10}/).nil?
      raise ArgumentError, 'ToParticispant is not valid'    if csv[4].match(/.{1,10}/).nil?

      nem12_100 = {
        :record_indicator => csv[0].to_i,
        :version_header   => csv[1],
        :datetime         => Time.parse("#{csv[2]}+1000"),
        :from_participant => csv[3],
        :to_participant   => csv[4]
      }
    end
    
    # Parses the NMI Data Details
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def parse_nem12_200(line)
      csv = line.parse_csv

      raise ArgumentError, 'RecordIndicator is not 200'     if csv[0] != '200'
      raise ArgumentError, 'NMI is not valid'               if csv[1].match(/[A-Z0-9]{10}/).nil?
      raise ArgumentError, 'NMIConfiguration is not valid'  if csv[2].match(/.{1,240}/).nil?
      unless csv[3].nil?
        raise ArgumentError, 'RegisterID is not valid'        if csv[3].match(/.{1,10}/).nil?
      end
      raise ArgumentError, 'NMISuffix is not valid'         if csv[4].match(/[A-HJ-NP-Z][1-9A-HJ-NP-Z]/).nil?
      unless csv[5].nil?
        raise ArgumentError, 'MDMDataStreamIdentifier is not valid' if csv[5].match(/[A-Z0-9]{2}/).nil?
      end
      raise ArgumentError, 'MeterSerialNumber is not valid' if csv[6].match(/[A-Z0-9]{2}/).nil?
      raise ArgumentError, 'UOM is not valid'               if csv[7].upcase.match(/[A-Z0-9]{2}/).nil?
      raise ArgumentError, 'UOM is not valid'               unless UOM.keys.map{|k| k.upcase}.include?(csv[7].upcase)
      raise ArgumentError, 'IntervalLength is not valid'    unless %w(1 5 10 15 30).include?(csv[8])
      # raise ArgumentError, 'NextScheduledReadDate is not valid' if csv[9].match(/\d{8}/).nil? || csv[9] != Time.parse("#{csv[9]}").strftime('%Y%m%d')
      
      @nmi = csv[1]

      # Push onto the stack
      @data_details << {
        :record_indicator => csv[0].to_i,
        :nmi => csv[1],
        :nmi_configuration => csv[2],
        :register_id => csv[3],
        :nmi_suffix => csv[4],
        :mdm_data_streaming_identifier => csv[5],
        :meter_serial_nubmer => csv[6],
        :uom => csv[7].upcase,
        :interval_length => csv[8].to_i,
        :next_scheduled_read_date => csv[9],
      }
    end
    
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def parse_nem12_300(line)
      csv = line.parse_csv

      raise TypeError, 'Expected NMI Data Details to exist with IntervalLength specified' if @data_details.last.nil? || @data_details.last[:interval_length].nil?
      number_of_intervals = 1440 / @data_details.last[:interval_length]
      intervals_offset = number_of_intervals + 2
      
      raise ArgumentError, 'RecordIndicator is not 300'     if csv[0] != '300'
      raise ArgumentError, 'IntervalDate is not valid'      if csv[1].match(/\d{8}/).nil? || csv[1] != Time.parse("#{csv[1]}").strftime('%Y%m%d')
      (2..(number_of_intervals+1)).each do |i|
        raise ArgumentError, "Interval number #{i-1} is not valid"              if csv[i].match(/\d+(\.\d+)?/).nil?
      end
      raise ArgumentError, 'QualityMethod is not valid'     unless csv[intervals_offset + 0].class == String
      raise ArgumentError, 'QualityMethod does not have valid length'           unless [1,3].include?(csv[intervals_offset + 0].length)
      raise ArgumentError, 'QualityMethod does not have valid QualityFlag'      unless QUALITY_FLAGS.keys.include?(csv[intervals_offset + 0][0])
      unless %w(A N V).include?(csv[intervals_offset + 0][0])
        raise ArgumentError, 'QualityMethod does not have valid length'         unless csv[intervals_offset + 0].length == 3
        raise ArgumentError, 'QualityMethod does not have valid MethodFlag'     unless METHOD_FLAGS.keys.include?(csv[intervals_offset + 0][1..2])
      end
      unless %w(A N E).include?(csv[intervals_offset + 0][0])
        raise ArgumentError, 'ReasonCode is not valid'      unless REASON_CODES.keys.include?(csv[intervals_offset + 1].to_i)
      end
      if !csv[intervals_offset + 1].nil? && csv[intervals_offset + 1].to_i == 0
        raise ArgumentError, 'ReasonDescription is not valid'                   unless csv[intervals_offset + 2].class == String && csv[intervals_offset + 2].length > 0
      end
      raise ArgumentError, 'UpdateDateTime is not valid'   if csv[intervals_offset + 3].match(/\d{14}/).nil? || csv[intervals_offset + 3] != Time.parse("#{csv[intervals_offset + 3]}").strftime('%Y%m%d%H%M%S')
      unless csv[intervals_offset + 4].nil?
        raise ArgumentError, 'MSATSLoadDateTime is not valid'   if csv[intervals_offset + 4].match(/\d{14}/).nil? || csv[intervals_offset + 4] != Time.parse("#{csv[intervals_offset + 4]}").strftime('%Y%m%d%H%M%S')
      end
      
      base_datetime = Time.parse("#{csv[1]}000000+1000")
      base_interval = { :data_details => @data_details.last, :datetime => Time.parse("#{csv[1]}000000+1000"), :value => nil, :flag => nil}
      (2..(number_of_intervals+1)).each do |i|
        interval = base_interval.dup
        interval[:datetime] += (i-1) * interval[:data_details][:interval_length] * 60
        interval[:value] = csv[i].to_f
        @interval_data << interval
      end
    end
    
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def parse_nem12_400(line)
    end
    
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def parse_nem12_500(line)
    end
    
    # @param line [String] A single line in string format
    # @return [Hash] the line parsed into a hash of information
    def parse_nem12_900(line)
    end
    
    # @param nmi [String] a NMI that is to be checked for validity
    # @return [Boolean] determines if the NMI is valid
    def self.valid_nmi?(nmi)
      (nmi.class == String && nmi.length == 10 && !nmi.match(/^[A-Z1-9][A-Z0-9]{9}$/).nil?)
    end
    
    # @param path_to_file [String] the path to a file
    # @return [] NEM12 object 
    def self.parse_nem12_file(path_to_file)
      parse_nem12(File.read(path_to_file))
    end
        
    # @return [Array] array of a NEM12 file a given Meter + Data Stream for easy reading
    def to_a
      values = @interval_data.map{|d| [d[:data_details][:nmi],d[:data_details][:nmi_suffix].upcase,d[:data_details][:uom],d[:datetime].strftime("%Y%m%d%H%M%S+%Z"),d[:value]]}
      ([headers] + values)
    end
    
    # @return [Array] CSV of a NEM12 file a given Meter + Data Stream for easy reading
    def to_csv
      headers = ['nmi','suffix','units','datetime','value']
      ([headers]+self.to_a).map{|row| row.join(',')}.join("\n")
    end
    
    # @param contents [String] the path to a file
    # @return [Array[AEMO::NEM12]] An array of NEM12 objects
    def self.parse_nem12(contents)
      file_contents = contents.gsub(/\r/,"\n").gsub(/\n\n/,"\n").split("\n").delete_if{|line| line.empty? }
      raise ArgumentError, 'First row should be have a RecordIndicator of 100 and be of type Header Record' unless file_contents.first.parse_csv[0] == '100'
      
      nem12s = []
      nem12_100 = AEMO::NEM12.parse_nem12_100(file_contents.first)
      nem12 = nil
      file_contents.each do |line|
        case line[0..2].to_i
        when 200
          if nem12.nil? || line[4..13] != nem12.nmi
            nem12s << AEMO::NEM12.new('')
          end
          nem12 = nem12s.last
          nem12.parse_nem12_200(line)
        when 300
          nem12.parse_nem12_300(line)
        # when 400
        #   nem12s.last.interval_events << nem12.parse_nem12_400(line)
        # when 500
        #   nem12s.last.b2b_details = nem12.parse_nem12_500(line)
        when 900
          @nem12_900 = nem12.parse_nem12_900(line)
        end
      end
      nem12s
    end

    
  end
end