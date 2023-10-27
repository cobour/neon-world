package de.spozzfroin.amiga.datafilecreator.config;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class Config {

	private String sourceFolder = "";

	private String tempFolder = "";

	private String indexFilename = "";

	private String descriptorFilename = "";

	private List<String> targetFolders = new ArrayList<>();

	private List<TargetFile> targetFiles = new ArrayList<>();

	// not read from yaml, but calculated from config file
	private String baseFolder = "";

	public String getSourceFolder() {
		return this.baseFolder + (this.sourceFolder.endsWith("/") ? this.sourceFolder : this.sourceFolder + "/");
	}

	public String getTempFolder() {
		return this.baseFolder + (this.tempFolder.endsWith("/") ? this.tempFolder : this.tempFolder + "/");
	}

	public String getIndexFilename() {
		return this.baseFolder + this.indexFilename;
	}

	public String getDescriptorFilename() {
		return this.baseFolder + this.descriptorFilename;
	}

	public List<String> getTargetFolders() {
		return this.targetFolders.stream() //
				.map(tf -> this.baseFolder + tf) //
				.map(tf -> tf.endsWith("/") ? tf : tf + "/") //
				.collect(Collectors.toList());
	}

	public List<TargetFile> getTargetFiles() {
		return this.targetFiles;
	}

	void setBaseFolder(String baseFolder) {
		this.baseFolder = baseFolder.endsWith("/") ? baseFolder : baseFolder + "/";
	}
}
