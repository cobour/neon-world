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

	// only valid for tiled files. indicates that for each row/column a free spot is
	// found for player to be respawned.
	// default: do not create
	private boolean createRespawnInfo = false;

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

	public void setFilename(String filename) {
		this.filename = filename;
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

	public void setWithoutMask(boolean withoutMask) {
		this.withoutMask = withoutMask;
	}

	public boolean isColumnOrientation() {
		return this.columnOrientation;
	}

	public void setColumnOrientation(boolean columnOrientation) {
		this.columnOrientation = columnOrientation;
	}

	public String getTilesFilename() {
		return this.tilesFilename;
	}

	public void setTilesFilename(String tilesFilename) {
		this.tilesFilename = tilesFilename;
	}

	public boolean isCreateRespawnInfo() {
		return this.createRespawnInfo;
	}

	public void setCreateRespawnInfo(boolean createRespawnInfo) {
		this.createRespawnInfo = createRespawnInfo;
	}
}
