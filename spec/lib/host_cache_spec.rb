describe RunLoop::HostCache do

  let(:directory) { Dir.mktmpdir }
  let(:cache_filename) { '2780e6479cc2bfcd0a007bd08bdf36de11b397bd' }

  describe '.new' do

    after(:each) { FileUtils.rm_rf(File.expand_path('./host_cache.db')) }

    it 'when directory exists' do
      cache = RunLoop::HostCache.new(directory)
      expect(cache.path).to be == File.join(directory, cache_filename)
    end

    it 'when directory does not exist' do
      new_dir = File.join(directory, '.calabash')
      cache = RunLoop::HostCache.new(new_dir)
      expect(cache.path).to be == File.join(new_dir, cache_filename)
      expect(Dir.exist?(new_dir))
    end

    it 'respects :filename option' do
      filename = 'host_cache.db'
      cache = RunLoop::HostCache.new(directory, {filename:filename})
      expect(cache.path).to be == File.join(directory, filename)
    end

    it 'respects :clear option' do
      filename = 'host_cache.db'
      expected_path = File.join(directory, filename)
      FileUtils.touch(filename)
      cache = RunLoop::HostCache.new(directory, {filename:filename, clear:true})
      expect(cache.path).to be == expected_path
      expect(File.exist?(expected_path)).to be == false
    end
  end

  describe '.default_directory' do

    let(:run_loop_dir) { '~/.run-loop' }
    let(:tmp_dir) { Dir.mktmpdir }

    before do
      expect(File).to receive(:expand_path).with(run_loop_dir).and_return(tmp_dir)
    end

    it 'returns directory if it exists' do
      expect(RunLoop::HostCache.default_directory).to be == tmp_dir
    end

    it 'creates a directory if it does not exist' do
      FileUtils.rm_rf(tmp_dir)
      expect(FileUtils).to receive(:mkdir).with(tmp_dir).and_call_original

      expect(RunLoop::HostCache.default_directory).to be == tmp_dir
    end

    it 'raises error if directory is actually a file' do
      expect(File).to receive(:directory?).and_return false

      expect do
        RunLoop::HostCache.default_directory
      end.to raise_error RuntimeError
    end
  end

  context '.default' do
    subject { RunLoop::HostCache.default }
    it {
      is_expected.not_to be nil
      is_expected.to be_a RunLoop::HostCache
    }
  end

  describe 'io' do
    let(:hash) { { :number => 1, :word => 'word', :symbol => :symbol } }
    describe '#read' do
      it 'returns an empty Hash if cache file does not exist' do
        cache = RunLoop::HostCache.new(directory)
        result = cache.read
        expect(result).to be_a Hash
        expect(result).to be == {}
      end
    end

    describe '#write' do
      let(:cache) { RunLoop::HostCache.new(directory) }
      describe 'raises error when' do
        it 'argument is nil' do
          expect { cache.write(nil) }.to raise_error ArgumentError
        end

        it 'argument is not a Hash' do
          expect { cache.write([]) }.to raise_error ArgumentError
        end

        it "argument cannot be Marshal.dump'ed" do
          hash = {:dir => StringIO.new('fifo') }
          expect { cache.write( hash ) }.to raise_error TypeError
        end
      end

      it "what it writes can be Marshal.load'ed" do
        expect(cache.write(hash)).to be == true

        actual = nil
        File.open(cache.path) do |file|
          actual = Marshal.load(file)
        end

        expect(actual).to be == hash
      end
    end

    describe '#clear' do
      it 'can clear the cache' do
        cache = RunLoop::HostCache.new(directory)
        expect(cache.write(hash)).to be == true
        expect(cache.read).to be == hash
        expect(cache.clear).to be == true
        expect(cache.read).to be == {}
      end
    end
  end
end
