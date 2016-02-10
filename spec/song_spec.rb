require 'radioactive/exception'
require 'radioactive/song'

describe Radioactive::Song do
  it 'can be created from a string' do
    song = Radioactive::Song.new('Adele - Hello')
    expect(song.artist).to eq 'Adele'
    expect(song.title).to eq 'Hello'
  end

  it 'can be created via keywords' do
    song = Radioactive::Song.new(artist: 'Adele', title: 'Hello')
    expect(song.artist).to eq 'Adele'
    expect(song.title).to eq 'Hello'
  end

  it 'cannot have an empty artist or title' do
    expect do
      Radioactive::Song.new('Adele')
    end.to raise_error Radioactive::Error

    expect do
      Radioactive::Song.new(' - Adele')
    end.to raise_error Radioactive::Error

    expect do
      Radioactive::Song.new(artist: nil)
    end.to raise_error Radioactive::Error
  end

  it 'can parse complex names' do
    song = Radioactive::Song.new('Adele -Hello (live - London)')
    expect(song.artist).to eq 'Adele'
    expect(song.title).to eq 'Hello (live - London)'
  end

  describe '#to_s' do
    it 'returns formated song name' do
      expect(Radioactive::Song.new(artist: 'Adele', title: 'Hello').to_s).to(
        eq 'Adele - Hello')
      expect(Radioactive::Song.new('  Adele-   Hello  ').to_s).to(
        eq 'Adele - Hello')
    end
  end

  it 'can be used as a key of a hash' do
    hash = {
      Radioactive::Song.new('Adele - Hello') => 42
    }
    expect(hash.key? Radioactive::Song.new('Adele-Hello')).to(
      eq true)
  end
end