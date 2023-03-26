import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap.SimpleEntry;
import java.util.List;

class SimpleCopySourceFileConverter implements SourceFileConverter {

    private final SourceFile sourceFile;

    SimpleCopySourceFileConverter(SourceFile theSourceFile) {
        this.sourceFile = theSourceFile;
    }

    @Override
    public void convertToRawData(FileOutputStream data) throws IOException {
        try (FileInputStream fis = new FileInputStream(sourceFile.filename)) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                data.write(buffer, 0, length);
            }
            data.flush();
        }
    }

    @Override
    public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
            throws IOException {
        String label = generateLabel(sourceFile.filename);
        Path src = Paths.get(sourceFile.filename);
        long size = Files.size(src);
        index.add(new SimpleEntry<>(label, Long.valueOf(size)));
    }
}
