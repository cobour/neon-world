import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.AbstractMap.SimpleEntry;

class TargetFile {

    static TargetFileBuilder builder() {
        return new TargetFileBuilder();
    }

    static class TargetFileBuilder {
        private String filename;
        private MemoryType memoryType;
        private List<SourceFile> sourceFiles = new ArrayList<>();

        private TargetFileBuilder() {
            super();
        }

        TargetFileBuilder file(String theFilename) {
            this.filename = theFilename;
            return this;
        }

        TargetFileBuilder memory(MemoryType theMemoryType) {
            this.memoryType = theMemoryType;
            return this;
        }

        TargetFileBuilder source(SourceFile aSourceFile) {
            this.sourceFiles.add(aSourceFile);
            return this;
        }

        TargetFile get() {
            return new TargetFile(filename, memoryType, sourceFiles);
        }
    }

    private final String filename;
    final MemoryType memoryType;
    final List<SourceFile> sourceFiles;
    final List<SimpleEntry<String, Long>> index = new ArrayList<>(); // for rs-structure
    final List<SimpleEntry<String, String>> constants = new ArrayList<>(); // additional equ's
    long sizeGzippedDataFile = -1;

    private TargetFile(String theFilename, MemoryType theMemoryType, List<SourceFile> theSourceFiles) {
        this.filename = theFilename;
        this.memoryType = theMemoryType;
        this.sourceFiles = theSourceFiles;
    }

    String getIdentifier() {
        return filename.toLowerCase();
    }

    Path getDataFile(boolean gzip) {
        StringBuilder sb = new StringBuilder("./data/converted/");
        sb.append(filename).append(".dat");
        if (!gzip) {
            sb.append(".tmp");
        }
        return Paths.get(sb.toString());
    }

    List<Path> getTargetDataFiles() {
        return Arrays.asList(Paths.get("./uae/dh0/" + filename + ".dat"),
                Paths.get("./uae/dh0_adf/" + filename + ".dat"));
    }

    void writeToIndexFile(PrintWriter writer) throws IOException {
        writer.println(" rsreset");
        index.stream().forEach(entry -> {
            String name = getIdentifier() + entry.getKey();
            Long size = entry.getValue();
            writer.println(name + ": rs.b " + size);
        });
        writer.println(getIdentifier() + "_size: rs.b 0");
        writer.println(getIdentifier() + "_filesize equ " + sizeGzippedDataFile);
        constants.stream().forEach(entry -> {
            String name = getIdentifier() + entry.getKey();
            writer.println(name + " equ " + entry.getValue());
        });
        writer.flush();
    }

    void writeToDescriptorFile(PrintWriter writer) throws IOException {
        writer.println(" xdef " + getIdentifier() + "_filename");
        writer.println(getIdentifier() + "_filename: dc.b \"" + filename + ".dat\",0");
        writer.println(" even");
        writer.flush();
    }
}
