import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap.SimpleEntry;

import java.util.Arrays;
import java.util.List;

class PtModSourceFileConverter implements SourceFileConverter {

    private final SourceFile sourceFile;
    private final TargetFile targetFile;
    private SimpleEntry<String, Long> indexEntry;

    PtModSourceFileConverter(SourceFile theSourceFile, TargetFile theTargetFile) {
        this.sourceFile = theSourceFile;
        this.targetFile = theTargetFile;
    }

    @Override
    public void convertToRawData(FileOutputStream data) throws IOException {
        byte[] allBytes = getAllBytes();
        int startPosOfSamples = getStartPosOfSamples(allBytes);
        writeToTargetFile(data, allBytes, startPosOfSamples);
    }

    private byte[] getAllBytes() throws IOException, FileNotFoundException {
        Path srcPath = Paths.get(sourceFile.filename);
        long filesize = Files.size(srcPath);
        byte[] allBytes = new byte[(int) filesize];
        try (FileInputStream fis = new FileInputStream(sourceFile.filename)) {
            fis.read(allBytes);
        }
        return allBytes;
    }

    private int getStartPosOfSamples(byte[] allBytes) {
        byte[] patternNoBytes = Arrays.copyOfRange(allBytes, 952, 1079);
        byte maxPatternNo = patternNoBytes[0];
        for (int i = 1; i < patternNoBytes.length; i++) {
            if (patternNoBytes[i] > maxPatternNo) {
                maxPatternNo = patternNoBytes[i];
            }
        }
        int startPosOfSamples = 1084 + (++maxPatternNo * 1024);
        return startPosOfSamples;
    }

    private void writeToTargetFile(FileOutputStream data, byte[] allBytes, int startPosOfSamples) throws IOException {
        byte[] bytesToWrite;
        String labelFragment;
        if (targetFile.memoryType == MemoryType.CHIP) {
            bytesToWrite = Arrays.copyOfRange(allBytes, startPosOfSamples, allBytes.length);
            labelFragment = "samples";
        } else {
            bytesToWrite = Arrays.copyOfRange(allBytes, 0, startPosOfSamples);
            labelFragment = "data";
        }
        //
        String label = generateLabel(sourceFile.filename, labelFragment);
        indexEntry = new SimpleEntry<>(label, Long.valueOf(bytesToWrite.length));
        //
        data.write(bytesToWrite);
    }

    @Override
    public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
            throws IOException {
        index.add(indexEntry);
    }
}
