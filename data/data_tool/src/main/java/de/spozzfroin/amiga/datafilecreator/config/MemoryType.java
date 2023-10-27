package de.spozzfroin.amiga.datafilecreator.config;

public enum MemoryType {
	CHIP, OTHER;

	public boolean isChip() {
		return this.equals(CHIP);
	}

	public boolean isOther() {
		return this.equals(OTHER);
	}
}
