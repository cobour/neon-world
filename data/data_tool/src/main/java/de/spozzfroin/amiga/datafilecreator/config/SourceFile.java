package de.spozzfroin.amiga.datafilecreator.config;

public class SourceFile {

	private String filename = "";

	// only valid for gfx files. indicates that no mask is required.
	// default: create mask for gfx files.
	private boolean withoutMask = false;

	// only valid for tiled files. indicates that output should be column orientated
	// instead of row orientated.
	// default: output is row orientated.
	private boolean columnOrientation = false;

	// only valid for tiled files. points to gfx file containing the tiles.
	// default: empty (unknown)
	private String tilesFilename = "";

	// no-args constructor for snakeyaml
	public SourceFile() {
		super();
	}

	// only used for tiles gfx file of TiledSourceFileConverter
	public SourceFile(String theFilename) {
		this.filename = theFilename;
		this.withoutMask = true;
	}

	public String getFilename() {
		return this.filename;
	}

	public String getFullFilename(Config config) {
		return config.getSourceFolder() + this.filename;
	}

	public String getType() {
		return this.filename.substring(this.filename.lastIndexOf('.') + 1).toLowerCase();
	}

	public boolean isWithoutMask() {
		return this.withoutMask;
	}

	public boolean isColumnOrientation() {
		return this.columnOrientation;
	}

	public String getTilesFilename() {
		return this.tilesFilename;
	}
}
