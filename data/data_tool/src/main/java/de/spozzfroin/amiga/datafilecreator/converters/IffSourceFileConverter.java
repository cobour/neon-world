package de.spozzfroin.amiga.datafilecreator.converters;

import de.spozzfroin.amiga.datafilecreator.config.Config;
import de.spozzfroin.amiga.datafilecreator.config.SourceFile;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

class IffSourceFileConverter implements SourceFileConverter {

    private static final Set<ChunkProcessor> CHUNK_PROCESSORS = new HashSet<>();

    static {
        CHUNK_PROCESSORS.add(new FormProcessor());
        CHUNK_PROCESSORS.add(new IlbmProcessor());
        CHUNK_PROCESSORS.add(new AnnoProcessor());
        CHUNK_PROCESSORS.add(new CrngProcessor());
        CHUNK_PROCESSORS.add(new DppsProcessor());
        CHUNK_PROCESSORS.add(new BmhdProcessor());
        CHUNK_PROCESSORS.add(new CamgProcessor());
        CHUNK_PROCESSORS.add(new CmapProcessor());
        CHUNK_PROCESSORS.add(new BodyProcessor());
    }

    private final SourceFile sourceFile;

    private int width;
    private int height;
    private int bitplanes;
    private List<String> colors;
    private byte[] raw;
    private byte[] mask;

    IffSourceFileConverter(SourceFile theSourceFile) {
        this.sourceFile = theSourceFile;
    }

    @Override
    public void convertToRawData(Config config, OutputStream data) throws IOException {
        try (FileInputStream fis = new FileInputStream(this.sourceFile.getFullFilename(config))) {
            readSource(fis);
        }
        data.write(this.raw);
        if (!this.sourceFile.isWithoutMask()) {
            data.write(this.mask);
        }
    }

    @Override
    public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
            throws IOException {
        String label = generateLabel(this.sourceFile.getFilename());
        index.add(new SimpleEntry<>(label, Long.valueOf(this.raw.length)));
        if (!this.sourceFile.isWithoutMask()) {
            label = generateLabel(this.sourceFile.getFilename(), "mask");
            index.add(new SimpleEntry<>(label, Long.valueOf(this.mask.length)));
        }
    }

    private interface ChunkProcessor {
        String id();

        void process(FileInputStream src, IffSourceFileConverter uow) throws IOException;
    }

    private static class FormProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "FORM";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            src.skip(4); // file size not needed
        }
    }

    private static class IlbmProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "ILBM";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            // do nothing, just continue
        }
    }

    private static class AnnoProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "ANNO";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            src.skip(chunkSize);
        }
    }

    private static class CrngProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "CRNG";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            src.skip(chunkSize);
        }
    }

    private static class DppsProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "DPPS";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            src.skip(chunkSize);
        }
    }

    private static class BmhdProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "BMHD";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            src.skip(4); // chunk size not needed
            uow.width = readWord(src);
            uow.height = readWord(src);
            src.skip(4); // left and top not needed
            uow.bitplanes = readByte(src);
            int masking = readByte(src);
            if (masking != 0) {
                throw new UnsupportedOperationException("Masking not yet supported!");
            }
            int compress = readByte(src);
            if (compress != 1) {
                throw new UnsupportedOperationException("Uncompressed files not yet supported!");
            }
            src.skip(9); // padding byte and additional fields not needed
        }
    }

    private static class CamgProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "CAMG";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            src.skip(chunkSize);
        }
    }

    private static class CmapProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "CMAP";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            uow.colors = new ArrayList<>();
            byte[] colorBytes = new byte[chunkSize];
            src.read(colorBytes);
            //
            int i = 0;
            do {
                int red = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
                int green = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
                int blue = Byte.toUnsignedInt(colorBytes[i++]) >> 4;
                String color = "0" + Integer.toHexString(red) + Integer.toHexString(green) + Integer.toHexString(blue);
                uow.colors.add(color);
            } while (i < chunkSize);
        }
    }

    private static class BodyProcessor implements ChunkProcessor {
        @Override
        public String id() {
            return "BODY";
        }

        @Override
        public void process(FileInputStream src, IffSourceFileConverter uow) throws IOException {
            int chunkSize = readLong(src);
            byte[] compressed = new byte[chunkSize];
            src.read(compressed);
            //
            int rawSize = (uow.width * uow.height * uow.bitplanes) / 8;
            uow.raw = new byte[rawSize];
            uow.mask = new byte[rawSize];
            //
            readRawImageData(uow, chunkSize, compressed);
            //
            if (!uow.sourceFile.isWithoutMask()) {
                createMask(uow);
            }
        }

        private void readRawImageData(IffSourceFileConverter uow, int chunkSize, byte[] compressed) {
            int compressedIndex = 0;
            int rawIndex = 0;
            do {
                byte code = compressed[compressedIndex++];
                if (code == -128) {
                    // no-op
                } else if (code < 0) {
                    // repeat byte
                    byte repeatedByte = compressed[compressedIndex++];
                    int count = code;
                    count *= -1;
                    for (int i = 0; i < count + 1; i++) {
                        uow.raw[rawIndex++] = repeatedByte;
                    }
                } else {
                    // copy bytes
                    int copyBytesCount = code;
                    for (int i = 0; i < copyBytesCount + 1; i++) {
                        uow.raw[rawIndex++] = compressed[compressedIndex++];
                    }
                }
            } while (compressedIndex < chunkSize);
        }

        private void createMask(IffSourceFileConverter uow) {
            final int bytesPerRow = uow.width / 8;
            for (int row = 0; row < uow.height; row++) {
                for (int col = 0; col < (uow.width / 8); col++) {
                    // or all bytes together
                    byte mask = 0;
                    for (int bitplane = 0; bitplane < uow.bitplanes; bitplane++) {
                        int i = (row * bytesPerRow * uow.bitplanes) + (bitplane * bytesPerRow) + col;
                        mask = (byte) (mask | uow.raw[i]);
                    }
                    // write mask to all bitplanes (because of interleaved format)
                    for (int bitplane = 0; bitplane < uow.bitplanes; bitplane++) {
                        int i = (row * bytesPerRow * uow.bitplanes) + (bitplane * bytesPerRow) + col;
                        uow.mask[i] = mask;
                    }
                }
            }
        }
    }

    private void readSource(FileInputStream src) throws IOException {
        int availableBytes = Integer.MAX_VALUE;
        do {
            String chunkID = readChunkID(src);
            ChunkProcessor chunkProcessor = getChunkProcessor(chunkID);
            chunkProcessor.process(src, this);
            availableBytes = src.available();
        } while (availableBytes > 3); // everything less than 4 bytes is invalid data (padding bytes)
    }

    private static String readChunkID(FileInputStream src) throws IOException {
        byte[] bytes = new byte[4];
        src.read(bytes);
        return new String(bytes);
    }

    private static ChunkProcessor getChunkProcessor(String chunkID) {
        Optional<ChunkProcessor> opt = CHUNK_PROCESSORS.stream().filter(p -> p.id().equals(chunkID)).findFirst();
        if (opt.isPresent()) {
            return opt.get();
        }
        throw new IllegalStateException(String.format("No ChunkProcessor found for ID: %s", chunkID));
    }

    private static int readLong(FileInputStream src) throws IOException {
        byte[] bytes = new byte[4];
        src.read(bytes);
        return (bytes[0] << 24) & 0xff000000 | (bytes[1] << 16) & 0x00ff0000 | (bytes[2] << 8) & 0x0000ff00
                | (bytes[3] << 0) & 0x000000ff;
    }

    private static int readWord(FileInputStream src) throws IOException {
        byte[] bytes = new byte[2];
        src.read(bytes);
        return (bytes[0] << 8) & 0x0000ff00 | (bytes[1] << 0) & 0x000000ff;
    }

    private static int readByte(FileInputStream src) throws IOException {
        byte[] bytes = new byte[1];
        src.read(bytes);
        return bytes[0];
    }

    int getWidth() {
        return this.width;
    }

    int getBitplanes() {
        return this.bitplanes;
    }
}
