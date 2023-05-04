
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.GZIPOutputStream;

public class Converter {

    static final List<TargetFile> targetFiles = new ArrayList<>();

    @FunctionalInterface
    interface MetadataOperation {
        void addMetadata(PrintWriter writer, TargetFile tf) throws IOException;
    }

    static {
        TargetFile target = TargetFile.builder().file("F000").memory(MemoryType.CHIP)
                .source(SourceFile.builder().file("./data/tiles.iff").param(ParamType.WITHOUT_MASK, "true").get())
                .source(SourceFile.builder().file("./data/vision.mod").get())
                .source(SourceFile.builder().file("./data/sfxr/select.wav").get())
                .source(SourceFile.builder().file("./data/sfxr/enter.wav").get())
                .get();
        targetFiles.add(target);
        //
        target = TargetFile.builder().file("F001").memory(MemoryType.OTHER)
                .source(SourceFile.builder().file("./data/tiled/mainmenu.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/start_on_off.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/exit_on_off.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/mm_lightning_anim.tmx").get())
                .source(SourceFile.builder().file("./data/vision.mod").get())
                .get();
        targetFiles.add(target);
        //
        target = TargetFile.builder().file("F002").memory(MemoryType.CHIP)
                .source(SourceFile.builder().file("./data/universe.mod").get())
                .source(SourceFile.builder().file("./data/tiles.iff").get())
                .source(SourceFile.builder().file("./data/sfxr/explosion.wav").get())
                .source(SourceFile.builder().file("./data/sfxr/shot.wav").get())
                .source(SourceFile.builder().file("./data/sfxr/explosion_small.wav").get())
                .get();
        targetFiles.add(target);
        //
        target = TargetFile.builder().file("F003").memory(MemoryType.OTHER)
                .source(SourceFile.builder().file("./data/tiled/level1.tmx")
                        .param(ParamType.COLUMN_ORIENTATION, "true")
                        .get())
                .source(SourceFile.builder().file("./data/tiled/player_anim_horizontal.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/player_anim_up.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/player_anim_down.tmx").get())
                .source(SourceFile.builder().file("./data/tiled/explosion_anim.tmx").get())
                .source(SourceFile.builder().file("./data/universe.mod").get())
                .get();
        targetFiles.add(target);
    }

    public static void main(String[] args) {
        new Converter().convertAll();
    }

    private void convertAll() {
        targetFiles.stream().forEach(this::convert);
        writeIndexFile();
        writeDescriptorFile();
    }

    private void convert(TargetFile targetFile) {
        processAllSourceFiles(targetFile);
        Path gzippedDataFile = gzipDataFile(targetFile);
        copyToDestinationFolders(targetFile, gzippedDataFile);
    }

    private void processAllSourceFiles(TargetFile targetFile) {
        try (FileOutputStream data = new FileOutputStream(targetFile.getDataFile(false).toFile())) {
            targetFile.sourceFiles.stream().forEach(sourceFile -> {
                try {
                    SourceFileConverter converter = SourceFileConverterFactory.getFor(sourceFile, targetFile);
                    converter.convertToRawData(data);
                    converter.addToIndex(targetFile.index, targetFile.constants);
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });
            data.flush();
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private Path gzipDataFile(TargetFile targetFile) {
        Path gzippedDataFile = targetFile.getDataFile(true);
        try (GZIPOutputStream gos = new GZIPOutputStream(new FileOutputStream(gzippedDataFile.toFile()));
                FileInputStream fis = new FileInputStream(targetFile.getDataFile(false).toFile())) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                gos.write(buffer, 0, length);
            }
            gos.flush();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        // remove first 10 bytes (GZip-Header), not needed
        long size;
        byte[] contents;
        try {
            size = Files.size(gzippedDataFile);
            size -= 10;
            contents = new byte[(int) size];
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        try (FileInputStream fis = new FileInputStream(gzippedDataFile.toFile())) {
            fis.skip(10);
            fis.read(contents);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        try (FileOutputStream fos = new FileOutputStream(gzippedDataFile.toFile())) {
            fos.write(contents);
            fos.flush();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        //
        try {
            size = Files.size(gzippedDataFile);
            targetFile.sizeGzippedDataFile = size;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        return gzippedDataFile;
    }

    private void copyToDestinationFolders(TargetFile targetFile, Path gzippedDataFile) {
        targetFile.getTargetDataFiles().stream().forEach(file -> {
            try {
                Files.copy(gzippedDataFile, file, StandardCopyOption.REPLACE_EXISTING);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
    }

    private void writeIndexFile() {
        Path indexFile = Paths.get("./files_index.i");
        writeMetadataFile(indexFile, (writer, tf) -> tf.writeToIndexFile(writer));
    }

    private void writeDescriptorFile() {
        Path indexFile = Paths.get("./files_descriptor.i");
        writeMetadataFile(indexFile, (writer, tf) -> tf.writeToDescriptorFile(writer));
    }

    private void writeMetadataFile(Path metadataFile, MetadataOperation operation) {
        try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(metadataFile, Charset.forName("UTF-8")))) {
            writer.println("; generated " + LocalDateTime.now().toString());
            targetFiles.stream().forEach(tf -> {
                try {
                    operation.addMetadata(writer, tf);
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
