import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.StringReader;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.AbstractMap.SimpleEntry;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Node;

class TiledSourceFileConverter implements SourceFileConverter {

    private final SourceFile sourceFile;

    private static final int TILESET_TILES_PER_ROW = 20;
    private static final int TILESET_BYTES_PER_ROW = (320 / 8) * 16 * 4;

    private int size;
    private String width; // number of tiles
    private String height; // number of tiles

    TiledSourceFileConverter(SourceFile theSourceFile) {
        this.sourceFile = theSourceFile;
    }

    @Override
    public void addToIndex(List<SimpleEntry<String, Long>> index, List<SimpleEntry<String, String>> constants)
            throws IOException {
        String label = generateLabel(sourceFile.filename);
        index.add(new SimpleEntry<>(label, Long.valueOf(size)));
        //
        label = generateLabel(sourceFile.filename, "tiles_width");
        constants.add(new SimpleEntry<>(label, width));
        label = generateLabel(sourceFile.filename, "tiles_height");
        constants.add(new SimpleEntry<>(label, height));
        label = generateLabel(sourceFile.filename, "size");
        constants.add(new SimpleEntry<>(label, Integer.toString(size)));
    }

    @Override
    public void convertToRawData(FileOutputStream data) throws IOException {
        try {
            Document document = getDocument();
            Node dataNode = getDataNode(document);
            List<List<Integer>> allOffsets = readAndConvert(dataNode);
            write(allOffsets, data);
        } catch (IOException e) {
            throw e;
        } catch (Exception e) {
            throw new IOException(e);
        }
    }

    private Document getDocument() throws Exception {
        DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
        Document document = builder.parse(new File(sourceFile.filename));
        document.getDocumentElement().normalize();
        //
        Node mapNode = document.getElementsByTagName("map").item(0);
        //
        String orientation = mapNode.getAttributes().getNamedItem("orientation").getTextContent();
        if (!"orthogonal".equalsIgnoreCase(orientation)) {
            throw new IllegalArgumentException("invalid orientation");
        }
        //
        this.width = mapNode.getAttributes().getNamedItem("width").getTextContent().trim();
        this.height = mapNode.getAttributes().getNamedItem("height").getTextContent().trim();
        //
        String renderorder = mapNode.getAttributes().getNamedItem("renderorder").getTextContent();
        if (!"right-down".equalsIgnoreCase(renderorder)) {
            throw new IllegalArgumentException("invalid renderorder");
        }
        //
        return document;
    }

    private Node getDataNode(Document document) {
        Node dataNode = document.getElementsByTagName("data").item(0);
        String encoding = dataNode.getAttributes().getNamedItem("encoding").getTextContent();
        if (!"csv".equalsIgnoreCase(encoding)) {
            throw new IllegalArgumentException("invalid encoding");
        }
        return dataNode;
    }

    private List<List<Integer>> readAndConvert(Node dataNode) throws IOException {
        List<List<Integer>> allOffsets = new ArrayList<>();
        String content = dataNode.getTextContent().trim();
        BufferedReader reader = new BufferedReader(new StringReader(content));
        String line = null;
        while ((line = reader.readLine()) != null) {
            List<String> lineTiles = Arrays.asList(line.trim().split(","));
            List<Integer> lineOffsets = new ArrayList<>();
            lineTiles.stream().forEach(tileString -> {
                int tile = Integer.parseInt(tileString) - 1; // values in file start at 1, we need start at zero
                int rowIndex = tile / TILESET_TILES_PER_ROW; // giving zero-based row number
                int columnIndex = ((tile) % TILESET_TILES_PER_ROW); // zero-based column of tile in row
                int offset = rowIndex * TILESET_BYTES_PER_ROW; // offset for row in tile-bitmap
                offset += (columnIndex * 2); // add x-offset for tile (16 pixels aka 2 bytes per tile)
                lineOffsets.add(Integer.valueOf(offset));
            });
            allOffsets.add(lineOffsets);
        }
        //
        if (this.sourceFile.getParamAsBoolean(ParamType.COLUMN_ORIENTATION)) {
            List<List<Integer>> columnAllOffsets = new ArrayList<>();
            AtomicInteger columnIndex = new AtomicInteger(0);
            allOffsets.get(0).stream().forEach(i -> { // iterate over first list representing first row -> one i for
                                                      // every column
                int index = columnIndex.getAndIncrement();
                List<Integer> column = allOffsets.stream().map(row -> row.get(index)).collect(Collectors.toList());
                columnAllOffsets.add(column);
            });
            return columnAllOffsets;
        }
        return allOffsets;
    }

    private void write(List<List<Integer>> allOffsets, FileOutputStream data) throws IOException {
        byte[] allBytes = createByteArray(allOffsets);
        data.write(allBytes);
    }

    private byte[] createByteArray(List<List<Integer>> allOffsets) {
        List<Integer> flatListAllOffsets = allOffsets.stream().flatMap(List::stream).collect(Collectors.toList());
        size = flatListAllOffsets.size() * 2;
        byte[] byteArray = new byte[size];
        AtomicInteger index = new AtomicInteger(0);
        flatListAllOffsets.stream().forEach(offset -> {
            if (offset.intValue() > 65535) {
                throw new RuntimeException("does not fit in word");
            }
            byte[] offsetByteArray = ByteBuffer.allocate(4).putInt(offset.intValue()).array();
            byteArray[index.getAndIncrement()] = offsetByteArray[2]; // just use low-word
            byteArray[index.getAndIncrement()] = offsetByteArray[3];
        });
        return byteArray;
    }
}
