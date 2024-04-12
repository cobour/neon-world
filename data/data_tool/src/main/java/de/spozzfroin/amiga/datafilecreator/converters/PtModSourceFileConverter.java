package de.spozzfroin.amiga.datafilecreator.converters;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap.SimpleEntry;
import java.util.Arrays;
import java.util.List;

import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.SourceFile;
import de.spozzfroin.amiga.datafilecreator.config.TargetFile;

class PtModSourceFileConverter implements SourceFileConverter {

	private final SourceFile sourceFile;
	private final TargetFile targetFile;
	private SimpleEntry<String, Long> indexEntry;

	PtModSourceFileConverter(SourceFile theSourceFile, TargetFile theTargetFile) {
		this.sourceFile = theSourceFile;
		this.targetFile = theTargetFile;
	}

	@Override
	public void convertToRawData(Config config, OutputStream data) throws IOException {
		byte[] allBytes = this.getAllBytes(config);
		int startPosOfSamples = this.getStartPosOfSamples(allBytes);
		this.writeToTargetFile(data, allBytes, startPosOfSamples);
	}

	private byte[] getAllBytes(Config config) throws IOException, FileNotFoundException {
		Path srcPath = Paths.get(this.sourceFile.getFullFilename(config));
		long filesize = Files.size(srcPath);
		byte[] allBytes = new byte[(int) filesize];
		try (FileInputStream fis = new FileInputStream(this.sourceFile.getFullFilename(config))) {
			fis.read(allBytes);
		}
		return allBytes;
	}

	private int getStartPosOfSamples(byte[] allBytes) {
		byte[] patternNoBytes = Arrays.copyOfRange(allBytes, 952, 1079);
		byte maxPatternNo = patternNoBytes[0];
		for (int i = 1; i < patternNoBytes.length; i++) {
			if (patternNoBytes[i] > maxPatternNo) {
				maxPatternNo = patternNoBytes[i];
			}
		}
		int startPosOfSamples = 1084 + (++maxPatternNo * 1024);
		return startPosOfSamples;
	}

	private void writeToTargetFile(OutputStream data, byte[] allBytes, int startPosOfSamples) throws IOException {
		byte[] bytesToWrite;
		String labelFragment;
		if (this.targetFile.getMemoryType().isChip()) {
			bytesToWrite = Arrays.copyOfRange(allBytes, startPosOfSamples, allBytes.length);
			labelFragment = "samples";
		} else {
			bytesToWrite = Arrays.copyOfRange(allBytes, 0, startPosOfSamples);
			labelFragment = "data";
		}
		//
		String label = this.generateLabel(this.sourceFile.getFilename(), labelFragment);
		this.indexEntry = new SimpleEntry<>(label, Long.valueOf(bytesToWrite.length));
		//
		data.write(bytesToWrite);
	}

	@Override
	public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
			throws IOException {
		index.add(this.indexEntry);
	}
}
