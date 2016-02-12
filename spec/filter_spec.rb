require 'radioactive/filter'
require 'radioactive/video'

describe Radioactive::Filter do
  def to_video(song)
    Radioactive::Video.new(
      id: '134',
      song: song,
      length: 0
    )
  end

  before :all do
    @filter = Radioactive::Filter.new
  end

  it 'only selects non-nil elements' do
    filtered = @filter.filter [
      $videos[:hello],
      nil,
      $videos[:fuel]
    ]

    expect(filtered).to eq [
      $videos[:hello],
      $videos[:fuel]
    ]

    expect(@filter.filter([nil, nil])).to be_empty
  end

  it 'only selects well-formated songs' do
    filtered = @filter.filter [
      $videos[:fire],
      to_video('Not well formated-'),
      to_video('Well-Formated (Live)')
    ]

    expect(filtered).to eq [
      $videos[:fire], 
      to_video('Well-Formated (Live)')
    ]
  end

  it 'only selects non-parody songs' do
    filtered = @filter.filter [
      $videos[:wall],
      to_video('Somewhat- well formated (parody)')
    ]

    expect(filtered).to eq [$videos[:wall]]
  end

  it 'only selects non-cover songs' do
    filtered = @filter.filter [
      $videos[:letgo],
      to_video('Lady Gaga - Born this Way (Parody)'),
      to_video('Writings on the Wall - Gibs cover')
    ]

    expect(filtered).to eq [$videos[:letgo]]
  end
end