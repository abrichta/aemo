require 'spec_helper'

describe AEMO::NEM12::NMIDataDetails do
  describe '#parse_csv' do
    it 'successfully parses a valid CSV string' do
      expect(AEMO::NEM12::NMIDataDetails.parse_csv('200,4001000007,B1E1K1Q1,,E1,N1,215085697,kWh,15,').class).to eq(AEMO::NEM12::Header)
    end
    it 'raises an error if not a string' do
      expect {AEMO::NEM12::NMIDataDetails.parse_csv(nil)}.to raise_error(ArgumentError)
    end
    it 'raises an error if not a valid CSV string' do
      expect {AEMO::NEM12::NMIDataDetails.parse_csv('300,20160324,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,A,,,20160325015730,')}.to raise_error(ArgumentError)
    end
  end
  # describe '#initialize' do
  #   it 'successfully creates a new AEMO::NEM12::Header with correct data' do
  #     expect(AEMO::NEM12::NMIDataDetails.new(DateTime.now,'BOB','ted').class).to eq(AEMO::NEM12::Header)
  #   end
  #   it 'raises error if file_created_at is not valid' do
  #     expect {AEMO::NEM12::NMIDataDetails.new(nil,'BOB','ted')}.to raise_error(ArgumentError)
  #   end
  #   it 'raises error if from_participant is not valid' do
  #     expect {AEMO::NEM12::NMIDataDetails.new(DateTime.now,nil,'ted')}.to raise_error(ArgumentError)
  #   end
  #   it 'raises error if to_participant is not valid' do
  #     expect {AEMO::NEM12::NMIDataDetails.new(DateTime.now,"BOB",nil)}.to raise_error(ArgumentError)
  #   end
  # end
end