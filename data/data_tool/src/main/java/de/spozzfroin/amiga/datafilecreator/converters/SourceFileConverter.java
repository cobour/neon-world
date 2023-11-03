package de.spozzfroin.amiga.datafilecreator.converters;

import de.spozzfroin.amiga.datafilecreator.config.Config;

import java.io.IOException;
import java.io.OutputStream;
import java.util.AbstractMap.SimpleEntry;
import java.util.List;

public interface SourceFileConverter {
    void convertToRawData(Config config, OutputStream data) throws IOException;

    void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
            throws IOException;

    default String generateLabel(String filename, String... additionalFragments) {
        StringBuilder sb = new StringBuilder("_dat_");
        sb.append(filename.substring(filename.lastIndexOf('/') + 1).replaceAll("\\.", "_").toLowerCase());
        if (additionalFragments.length > 0) {
            sb.append("_");
            sb.append(String.join("_", additionalFragments));
        }
        return sb.toString();
    }
}
