package de.spozzfroin.amiga.datafilecreator.converters;

import java.io.IOException;
import java.io.OutputStream;
import java.util.AbstractMap.SimpleEntry;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import de.spozzfroin.amiga.datafilecreator.config.Config;

public interface SourceFileConverter {
	void convertToRawData(Config config, OutputStream data) throws IOException;

	void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
			throws IOException;

	default String generateLabel(String filename, String... additionalFragments) {
		StringBuilder sb = new StringBuilder("_dat_");
		sb.append(filename.substring(filename.lastIndexOf('/') + 1).replaceAll("\\.", "_").toLowerCase());
		if (additionalFragments.length > 0) {
			sb.append("_");
			sb.append(Arrays.asList(additionalFragments).stream().collect(Collectors.joining("_")));
		}
		return sb.toString();
	}
}
