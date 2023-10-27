package de.spozzfroin.amiga.datafilecreator.converters;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.AbstractMap.SimpleEntry;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.SourceFile;

class WavSourceFileConverter implements SourceFileConverter {

	private static final Set<ChunkProcessor> CHUNK_PROCESSORS = new HashSet<>();

	static {
		CHUNK_PROCESSORS.add(new RiffProcessor());
		CHUNK_PROCESSORS.add(new FmtProcessor());
		CHUNK_PROCESSORS.add(new DataProcessor());
	}

	private final SourceFile sourceFile;

	private int hertz;
	private byte[] sampleData;

	WavSourceFileConverter(SourceFile theSourceFile) {
		this.sourceFile = theSourceFile;
	}

	@Override
	public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
			throws IOException {
		String label = generateLabel(sourceFile.getFilename());
		index.add(new SimpleEntry<>(label, Long.valueOf(sampleData.length)));
		//
		label = generateLabel(sourceFile.getFilename(), "length_in_words");
		constants.add(new SimpleEntry<>(label, Integer.toString(sampleData.length / 2)));
		int period = 3546895 / hertz;
		label = generateLabel(sourceFile.getFilename(), "period_pal");
		constants.add(new SimpleEntry<>(label, Integer.toString(period)));
		period = 3579546 / hertz;
		label = generateLabel(sourceFile.getFilename(), "period_ntsc");
		constants.add(new SimpleEntry<>(label, Integer.toString(period)));
	}

	@Override
	public void convertToRawData(Config config, OutputStream data) throws IOException {
		try (FileInputStream fis = new FileInputStream(sourceFile.getFullFilename(config))) {
			readSource(fis);
		}
		data.write(sampleData);
	}

	private interface ChunkProcessor {
		String id();

		void process(FileInputStream src, WavSourceFileConverter uow) throws IOException;
	}

	private static class RiffProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "RIFF";
		}

		@Override
		public void process(FileInputStream src, WavSourceFileConverter uow) throws IOException {
			src.skip(8); // skip filelength and 'WAVE'
		}
	}

	private static class FmtProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "fmt ";
		}

		@Override
		public void process(FileInputStream src, WavSourceFileConverter uow) throws IOException {
			src.skip(4); // length of chunk is always 16
			int format = readWord(src);
			if (format != 1) {
				throw new IllegalArgumentException("Wave-File needs to be in PCM-Format!");
			}
			src.skip(2); // channel count
			uow.hertz = readLong(src);
			src.skip(6); // frame size and rate
			int bits = readWord(src);
			if (bits != 8) {
				throw new IllegalArgumentException("Wave-File needs to have 8 bits!");
			}
		}
	}

	private static class DataProcessor implements ChunkProcessor {
		@Override
		public String id() {
			return "data";
		}

		@Override
		public void process(FileInputStream src, WavSourceFileConverter uow) throws IOException {
			int length = readLong(src) + 2; // add two null-bytes at beginning of sample data
			if ((length & 1) == 1) {
				length++; // even length
			}
			uow.sampleData = new byte[length];
			uow.sampleData[0] = 0;
			uow.sampleData[1] = 0;
			uow.sampleData[length - 1] = 0; // may have been added for the length to be even, then it is not contained
											// in src data
			for (int i = 2; i < length; i++) {
				int value = readByte(src);
				int highBit = value & 0x00000080;
				int otherBits = value & 0x0000007f;
				int target = otherBits;
				if (highBit == 0) { // invert highest bit in byte
					target += 128;
				}
				uow.sampleData[i] = (byte) target;
			}
		}
	}

	private void readSource(FileInputStream src) throws IOException {
		int availableBytes = Integer.MAX_VALUE;
		do {
			String chunkID = readChunkID(src);
			ChunkProcessor chunkProcessor = getChunkProcessor(chunkID);
			chunkProcessor.process(src, this);
			availableBytes = src.available();
		} while (availableBytes > 0);
	}

	private static String readChunkID(FileInputStream src) throws IOException {
		// ChunkID's are Big-Endian
		byte[] bytes = new byte[4];
		src.read(bytes);
		return new String(bytes);
	}

	private static ChunkProcessor getChunkProcessor(String chunkID) {
		Optional<ChunkProcessor> opt = CHUNK_PROCESSORS.stream().filter(p -> p.id().equals(chunkID)).findFirst();
		if (opt.isPresent()) {
			return opt.get();
		}
		throw new IllegalStateException(String.format("No ChunkProcessor found for ID: %s", chunkID));
	}

	private static int readLong(FileInputStream src) throws IOException {
		// Values are Little-Endian
		byte[] bytes = new byte[4];
		src.read(bytes);
		return (bytes[3] << 24) & 0xff000000 | (bytes[2] << 16) & 0x00ff0000 | (bytes[1] << 8) & 0x0000ff00
				| (bytes[0] << 0) & 0x000000ff;
	}

	private static int readWord(FileInputStream src) throws IOException {
		// Values are Little-Endian
		byte[] bytes = new byte[2];
		src.read(bytes);
		return (bytes[1] << 8) & 0x0000ff00 | (bytes[0] << 0) & 0x000000ff;
	}

	private static int readByte(FileInputStream src) throws IOException {
		byte[] bytes = new byte[1];
		src.read(bytes);
		return bytes[0];
	}
}
