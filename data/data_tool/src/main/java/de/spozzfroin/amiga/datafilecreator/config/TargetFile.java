package de.spozzfroin.amiga.datafilecreator.config;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class TargetFile {

	private String filename = "";
	private String memoryType = "";
	private List<SourceFile> sourceFiles = new ArrayList<>();

	// used during conversion
	private final List<SimpleEntry<String, Long>> index = new ArrayList<>(); // for rs-structure
	private final List<SimpleEntry<String, String>> constants = new ArrayList<>(); // additional equ's
	private long sizeGzippedDataFile = -1;

	public String getFilename() {
		return this.filename;
	}

	public MemoryType getMemoryType() {
		return MemoryType.valueOf(this.memoryType);
	}

	public List<SourceFile> getSourceFiles() {
		return this.sourceFiles;
	}

	public List<SimpleEntry<String, Long>> getIndex() {
		return this.index;
	}

	public List<SimpleEntry<String, String>> getConstants() {
		return this.constants;
	}

	public void setSizeGzippedDataFile(long sizeGzippedDataFile) {
		this.sizeGzippedDataFile = sizeGzippedDataFile;
	}

	public String getIdentifier() {
		return this.filename.toLowerCase();
	}

	public Path getDataFile(Config config, boolean gzip) {
		StringBuilder sb = new StringBuilder(config.getTempFolder());
		sb.append(this.filename).append(".dat");
		if (!gzip) {
			sb.append(".tmp");
		}
		return Paths.get(sb.toString());
	}

	public List<Path> getTargetDataFiles(Config config) {
		return config.getTargetFolders().stream() //
				.map(tf -> tf + this.filename + ".dat") //
				.map(tf -> Paths.get(tf)) //
				.collect(Collectors.toList());
	}

	public void writeToIndexFile(PrintWriter writer) throws IOException {
		writer.println(" rsreset");
		this.index.stream().forEach(entry -> {
			String name = this.getIdentifier() + entry.getKey();
			Long size = entry.getValue();
			writer.println(name + ": rs.b " + size);
		});
		writer.println(this.getIdentifier() + "_size: rs.b 0");
		writer.println(this.getIdentifier() + "_filesize equ " + this.sizeGzippedDataFile);
		this.constants.stream().forEach(entry -> {
			String name = this.getIdentifier() + entry.getKey();
			writer.println(name + " equ " + entry.getValue());
		});
		writer.flush();
	}

	public void writeToDescriptorFile(PrintWriter writer) throws IOException {
		writer.println(" xdef " + this.getIdentifier() + "_filename");
		writer.println(this.getIdentifier() + "_filename: dc.b \"" + this.filename + ".dat\",0");
		writer.println(" even");
		writer.flush();
	}
}
